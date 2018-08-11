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
      print_report
    end

    private

    # TODO: this is a nightmare

    # NOTE:
    # - prepend_line_number does not work in the only_matches/with_line_numbers
    #   case, because there we have several lines
    # - proper_segments and proper_matches are terrible names
    # - highlighting is something that is common to all cases, so we could
    #   perhaps unify it somehow

    def write_report
      if @opts[:only_matches]
        @report =
          if @opts[:line_numbers]
            proper_matches = @matches.reject { |match| match.from == match.to }

            (0...proper_segments.length).map do |index|
              "#{@line_number}:#{proper_matches[index].from + 1}: #{proper_segments[index].highlight}"
            end.join("\n")
          else
            proper_segments.map(&:highlight).join("\n")
          end
      else
        @report = @text + "\n"
        @matches.reverse_each do |match|
          @report = process_match(match)
        end
        prepend_line_number
      end
    end

    def proper_segments
      @matches.map do |match|
        @text[match.from...match.to]
      end.reject(&:empty?)
    end

    def process_match(match)
      pre_match  = @report[0...match.from]
      the_match  = @report[match.from...match.to]
      post_match = @report[match.to...@report.length]

      pre_match + highlight(the_match) + post_match
    end

    def highlight(the_match)
      return the_match unless output_is_a_tty?
      the_match.highlight
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
