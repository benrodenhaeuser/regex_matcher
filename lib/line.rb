require_relative './string.rb'

module Rex
  class Line
    attr_accessor :text
    attr_accessor :position
    attr_reader   :matches

    def initialize(text, line_number)
      @text = text
      @line_number = line_number
      @position = 0
      @matches = []
    end

    def [](index)
      @text[index]
    end

    def to_s
      @text
    end

    def length
      @text.length
    end

    def cursor
      @text[@position]
    end

    def consume
      @position += 1
    end

    def report(opts, output)
      @opts = opts
      @output = output

      write_report
      prepend_line_number
      print_report
    end

    private

    def write_report
      if @opts[:only_matches]
        @report = matching_segments
      else
        @report = @text
        @matches.reverse_each do |match|
          @report = process_match(match)
        end
      end
    end

    def matching_segments
      segments = @matches.map { |match| self[match.from...match.to] }
      segments.reject(&:empty?).join(", ")
    end

    def process_match(match)
      pre        = @report[0...match.from]
      the_match  = @report[match.from...match.to]
      post       = @report[match.to...@report.length]

      pre + substitute(the_match) + post
    end

    def substitute(the_match)
      return the_match unless output_is_a_tty?
      the_match.red.underline
    end

    def output_is_a_tty?
      @output.isatty
    end

    def prepend_line_number
      return unless @opts[:line_numbers]
      @report = @line_number.to_s + ": " + @report
    end

    def print_report
      return unless @matches.first || @opts[:all_lines]
      @output.puts @report
    end
  end
end
