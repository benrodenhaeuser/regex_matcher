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

      rewrite_line
      prepend_line_number
      output_line
    end

    private

    def rewrite_line
      if @opts[:only_matches]
        @text = matching_segments
      else
        @matches.reverse_each do |match|
          @text = process_match(match)
        end
      end
    end

    def matching_segments
      segments = @matches.map { |match| self[match.from...match.to] }
      segments.reject(&:empty?).join(", ")
    end

    def process_match(match)
      pre        = self[0...match.from]
      the_match  = self[match.from...match.to]
      post       = self[match.to...length]

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
      @text = @line_number.to_s + ": " + @text
    end

    def output_line
      return unless @matches.first || @opts[:all_lines]
      @output.puts self
    end
  end
end
