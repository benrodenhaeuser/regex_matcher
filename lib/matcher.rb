require_relative './line.rb'
require_relative './match.rb'

module Rex
  class Matcher
    def initialize(automaton:, pad_width:, opts: {}, output:)
      @automaton   = automaton
      @pad_width   = pad_width
      @opts        = opts
      @output      = output
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

      loop do
        break unless @line.cursor
        @match = Match.new(@line.position)
        @automaton.reset

        find_match

        if @match.found?
          @matches << @match
          break if @opts[:one_match_per_line]
        end

        @line.position = [@match.from + 1, @match.to].compact.max
      end
    end

    def find_match
      loop do
        @match.to = @line.position if @automaton.terminal?
        break unless @automaton.step?(@line.cursor)
        @automaton.step!(@line.cursor)
        @line.consume
      end
    end

    def rewrite_line
      if @opts[:matching_segments_only]
        @line.text = matching_segments
      else
        @matches.reverse_each do |match|
          @line.text = process_match(match)
        end
      end
    end

    def matching_segments
      segments = @matches.map { |match| @line[match.from...match.to] }
      segments.reject { |segment| segment.empty? }.join(", ")
    end

    def process_match(match)
      pre        = @line[0...match.from]
      the_match  = @line[match.from...match.to]
      post       = @line[match.to...@line.length]

      pre + substitute(the_match) + post
    end

    def substitute(the_match)
      if output_is_a_tty? && @opts[:substitution]
        @opts[:substitution].red.underline
      elsif output_is_a_tty?
        the_match.red.underline
      elsif @opts[:substitution]
        @opts[:substitution]
      else
        the_match
      end
    end

    def output_is_a_tty?
      @output.isatty
    end

    def prepend_line_number
      return unless @opts[:line_numbers]
      pad = format("%0#{@pad_width}d: ", @line_number.to_s)
      @line.text = pad + @line.text
    end

    def output_line
      return unless @matches.first || @opts[:all_lines]
      @output.puts @line
    end
  end
end
