require 'colorize'

require_relative './parser.rb'
require_relative './automaton.rb'
require_relative './line.rb'
require_relative './match.rb'

module Rex
  class Engine
    DEFAULT_OPTIONS = {
      line_numbers:       true,
      global_matching:    true,
      non_matching_lines: false,
      only_matches:       false
    }.freeze

    def initialize(pattern:, path:, substitution: nil, user_options: {})
      @pattern      = pattern
      @path         = path
      @substitution = substitution
      @opts         = DEFAULT_OPTIONS.merge(user_options)
      @automaton    = Parser.new(@pattern).parse.to_automaton.to_dfa
    end

    def run
      file = File.open(@path)
      @line_number = 1

      until file.eof?
        @line = Line.new(file.gets.chomp)
        @matches = []

        find_matches
        process_matches
        prepend_line_number
        output

        @line_number += 1
      end

      file.close
    end

    private

    def find_matches
      while @line.cursor
        @match = Match.new(@line.position)
        @automaton.reset

        find_match

        if @match.found?
          @matches << @match
          break unless @opts[:global_matching]
        end

        @line.position = [@match.from + 1, @match.to].compact.max
      end
    end

    def find_match
      while @automaton.step?(@line.cursor)
        @automaton.step!(@line.cursor)
        @line.consume
        @match.to = @line.position if @automaton.terminal?
      end
    end

    def process_matches
      @matches.reverse_each do |match|
        process_match(match)
      end
    end

    def process_match(match)
      pre        = @line[0...match.from]
      the_match  = @line[match.from...match.to]
      post       = @line[match.to...@line.length]
      @line.text = pre + replace(the_match) + post
    end

    def replace(the_match)
      if tty? && @substitution
        @substitution.colorize(:light_green).underline
      elsif tty?
        the_match.colorize(:light_green).underline
      elsif @substitution
        @substitution
      else
        the_match
      end
    end

    def tty?
      $stdout.isatty
    end

    def prepend_line_number
      return unless @opts[:line_numbers]
      pad = format("%0#{line_count.length}d:  ", @line_number.to_s)
      @line.text = pad + @line.text
    end

    def line_count
      @line_count ||= `wc -l #{@path}`.split.first
    end

    def output
      return unless !@matches.empty? || @opts[:non_matching_lines]
      puts @line
    end
  end
end
