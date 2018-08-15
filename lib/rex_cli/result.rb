require_relative './highlighted_string.rb'

module Rex
  class Result
    def initialize(text, matches)
      @text = text
      @matches = matches
    end

    def report!(input, opts)
      line_report = report(input, opts)
      puts line_report if line_report
    end

    def report(input, opts)
      return nil if @matches.empty? && !opts[:all_lines]

      @lineno   = input.file.lineno
      @filename = input.filename
      @opts     = opts

      @opts[:only_matches] ? only_matches_report : text_with_matches_report
    end

    private

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
      my_report.join("\n")
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
      @opts[:file_names] ? "#{File.basename(@filename)}:" : ""
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
  end
end
