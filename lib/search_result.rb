require_relative './string.rb'

module Rex
  class SearchResult
    def initialize(text, line_number, matches)
      @text = text
      @line_number = line_number
      @matches = matches
    end

    def count_matches
      @matches.reject(&:empty?).count
    end

    def report(opts, output, path)
      @opts = opts
      @output = output
      @path = path

      print_report(make_report)
    end

    private

    def make_report
      @opts[:only_matches] ? only_matches_report : text_with_matches_report
    end

    def only_matches_report
      @matches.map do |match|
        [
          highlight(prefix(match), :dim),
          " ",
          highlight(@text[match.from...match.to], :red_underline)
        ].join
      end.map(&:lstrip)
    end

    def text_with_matches_report
      [
        highlight(prefix, :dim),
        " ",
        @matches.reverse.inject(@text) do |text, match|
          pre_match  = text[0...match.from]
          the_match  = text[match.from...match.to]
          post_match = text[match.to...text.length]

          pre_match + highlight(the_match, :red_underline) + post_match
        end.lstrip
      ].join
    end

    def prefix(match = nil)
      return filename unless @opts[:line_numbers]

      if match
        "#{filename}#{@line_number}:#{match.from + 1}:"
      else
        "#{filename}#{@line_number}:"
      end
    end

    def filename
      @opts[:print_file_names] ? "#{File.basename(@path)}:" : ""
    end

    def highlight(text, style)
      case @opts[:highlight]
      when true then text.highlight(style)
      when false then text
      else
        output_is_a_tty? ? text.highlight(style) : text
      end
    end

    def output_is_a_tty?
      @output.isatty
    end

    def print_report(report)
      return if @matches.empty? && !@opts[:all_lines]
      @output.puts report
    end
  end
end
