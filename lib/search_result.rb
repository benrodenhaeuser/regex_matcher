require_relative './string.rb'

module Rex
  class SearchResult
    def initialize(text, row, matches)
      @text = text
      @row = row
      @matches = matches
    end

    def count_matches
      @matches.reject(&:empty?).count
    end

    def report(opts, output)
      @opts = opts
      @output = output

      write_report
      print_report
    end

    private

    # NOTE:
    # - prepend_line_number does not work in the only_matches/with_line_numbers
    #   case, because there we have several lines. so we seem to need a
    #   distinction there.
    # - proper_segments and proper_matches are terrible names
    # - highlighting is something that is common to all cases, so we could
    #   perhaps unify it somehow

    # three kinds of prefixes:
    # - empty
    # - with line number + ": "
    # - with line number + ":" + column number + " "
    #
    # maybe we should prepare an array of "report lines" (= strings)

    def write_report
      if @opts[:only_matches]
        @report =
          if @opts[:line_numbers]
            proper_matches = @matches.reject { |match| match.from == match.to }
            (0...proper_segments.length).map do |index|
              col = proper_matches[index].from + 1
              "#{@row}:#{col}: #{highlight(proper_segments[index])}"
            end.join("\n")
          else
            proper_segments.map { |item| highlight(item) }.join("\n")
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
      case @opts[:highlight]
      when true then return the_match.highlight
      when false then return the_match
      else
        return the_match.highlight if output_is_a_tty?
        the_match
      end
    end

    def output_is_a_tty?
      @output.isatty
    end

    def prepend_line_number
      return unless @opts[:line_numbers]
      @report = @row.to_s + ": " + @report
    end

    def print_report
      return unless @matches.first || @opts[:all_lines]
      @output.puts @report
    end
  end
end
