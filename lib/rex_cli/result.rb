require_relative './colored_string.rb'

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

      @lineno = input.current_file.lineno
      @path   = input.current_file.path
      @opts   = opts

      @opts[:only_matches] ? only_matches_report : text_with_matches_report
    end

    private

    def only_matches_report
      the_matches = @matches.map do |match|
        color(@text[match.from...match.to], :red_underline)
      end

      the_prefixes = @matches.map do |match|
        color(prefix(match), :dim)
      end

      the_prefixes.zip(the_matches).map(&:join).join("\n")
    end

    def text_with_matches_report
      the_line = @matches.reverse.inject(@text) do |text, match|
        pre_match  = text[0...match.from]
        the_match  = text[match.from...match.to]
        post_match = text[match.to...text.length]

        pre_match + color(the_match, :red_underline) + post_match
      end

      the_line.lstrip! unless @opts[:whitespace]

      color(prefix, :dim) + the_line
    end

    def prefix(match = nil)
      filename = @opts[:file_names] ? format_path(@path) : nil
      col  = @opts[:only_matches] && @opts[:line_numbers] ? match.from + 1 : nil

      row =
        case @opts[:line_numbers]
        when true then @lineno
        when false then nil
        else
          @path != Input::STDIN_PATH ? @lineno : nil
        end

      the_prefix = [filename, row, col].compact.join(':')
      the_prefix.empty? ? the_prefix : the_prefix + ': '
    end

    def format_path(path)
      path[0..1] == './' ? path[2...path.length] : path
    end

    def color(text, style)
      return text if text.empty?

      case @opts[:color]
      when true then text.color(style)
      when false then text
      else
        $stdout.isatty ? text.color(style) : text
      end
    end
  end
end
