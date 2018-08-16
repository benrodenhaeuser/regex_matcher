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
      the_matches = @matches.map do |match|
        highlight(@text[match.from...match.to], :red_underline)
      end

      the_prefixes = @matches.map do |match|
        highlight(prefix(match), :dim)
      end

      the_prefixes.zip(the_matches).map(&:join).join("\n")
    end

    def text_with_matches_report
      the_line = @matches.reverse.inject(@text) do |text, match|
        pre_match  = text[0...match.from]
        the_match  = text[match.from...match.to]
        post_match = text[match.to...text.length]

        pre_match + highlight(the_match, :red_underline) + post_match
      end

      the_line.lstrip! unless @opts[:whitespace]

      highlight(prefix, :dim) + the_line
    end

    def prefix(match = nil)
      file = @opts[:file_names]                           ? @filename      : nil
      row  = @opts[:line_numbers] && @filename != '-'     ? @lineno        : nil
      col  = @opts[:only_matches] && @opts[:line_numbers] ? match.from + 1 : nil

      the_prefix = [file, row, col].compact.join(':')
      the_prefix.empty? ? the_prefix : the_prefix + ': '
    end

    def highlight(text, style)
      return text if text.empty?

      case @opts[:highlight]
      when true then text.highlight(style)
      when false then text
      else
        $stdout.isatty ? text.highlight(style) : text
      end
    end
  end
end
