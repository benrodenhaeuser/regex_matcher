require_relative './string.rb'

module Rex
  class Result
    def initialize(text, matches)
      @text = text
      @matches = matches
    end

    def report(input, opts)
      @lineno   = input.file.lineno
      @filename = input.filename
      @opts     = opts

      print_report(make_report)
    end

    private

    def make_report
      @opts[:only_matches] ? only_matches_report : text_with_matches_report
    end

    def only_matches_report
      my_report = @matches.map do |match|
        # TODO: refactor concatenation logic
        if prefix.empty?
          highlight(@text[match.from...match.to], :red_underline)
        else
          [
            highlight(prefix(match), :dim),
            highlight(@text[match.from...match.to], :red_underline)
          ].join(" ")
        end
      end
      my_report.map!(&:lstrip) unless @opts[:whitespace]
      my_report
    end

    def text_with_matches_report
      my_report = @matches.reverse.inject(@text) do |text, match|
        pre_match  = text[0...match.from]
        the_match  = text[match.from...match.to]
        post_match = text[match.to...text.length]

        pre_match + highlight(the_match, :red_underline) + post_match
      end
      my_report.lstrip! unless @opts[:whitespace]

      # TODO: refactor concatenation logic
      if prefix.empty?
        my_report
      else
        [highlight(prefix, :dim), my_report].join(" ")
      end
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
      @opts[:print_file_names] ? "#{@filename}:" : ""
    end

    def lineno
      @lineno
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
