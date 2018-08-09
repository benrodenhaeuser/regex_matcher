require_relative './line.rb'
require_relative './match.rb'

module Rex
  class Matcher
    def initialize(automaton, line_count, opts)
      @automaton = automaton
      @line_count = line_count
      @opts = opts
      @line_number = 0
    end

    def match(text)
      @line = Line.new(text)
      @line_number += 1

      scan_line
      rewrite_line
      prepend_line_number
      output_line
    end

    private

    def scan_line
      @matches = []

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

    def rewrite_line
      if @opts[:only_matching_segments]
        matched_segments = @matches.map do |match|
          @line[match.from...match.to]
        end
        @line.text = matched_segments.join(" ")
      else
        @matches.reverse_each do |match|
          process_match(match)
        end
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
        @substitution.red.underline
      elsif tty?
        the_match.red.underline
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
      pad = format("%0#{@line_count.length}d:  ", @line_number.to_s)
      @line.text = pad + @line.text
    end

    def output_line
      return unless !@matches.empty? || @opts[:non_matching_lines]
      puts @line
    end
  end
end
