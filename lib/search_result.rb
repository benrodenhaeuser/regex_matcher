require_relative './string.rb'

module Rex
  class SearchResult
    def initialize(text, matches)
      @text = text
      @matches = matches
    end

    def count_matches
      @matches.reject(&:empty?).count
    end

    def report(opts, input)
      @opts  = opts
      @input = input

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
        "#{filename}#{lineno}:#{match.from + 1}:"
      else
        "#{filename}#{lineno}:"
      end
    end

    def filename
      @opts[:print_file_names] ? "#{@input.filename}:" : ""
    end

    def lineno
      @input.lineno
    end

    def highlight(text, style)
      case @opts[:highlight]
      when true then text.highlight(style)
      when false then text
      else
        $stdout.isatty ? text.highlight(style) : text
      end
    end

    def print_report(report)
      return if @matches.empty? && !@opts[:all_lines]
      puts report
    end
  end
end
