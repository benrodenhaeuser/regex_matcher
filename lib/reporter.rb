require_relative './string.rb'

class Reporter
  def initialize(pad_width:, opts:, output:)
    @pad_width = pad_width
    @opts = opts
    @output = output
    @line_number = 0
  end

  def report(result)
    @line = result[:line]
    @matches = result[:matches]
    @line_number += 1

    rewrite_line
    prepend_line_number
    output_line
  end

  def rewrite_line
    if @opts[:matching_segments_only]
      @line.text = matching_segments
    else
      @matches.reverse_each do |match|
        @line.text = process_match(match)
      end
    end
  end

  def matching_segments
    segments = @matches.map { |match| @line[match.from...match.to] }
    segments.reject(&:empty?).join(", ")
  end

  def process_match(match)
    pre        = @line[0...match.from]
    the_match  = @line[match.from...match.to]
    post       = @line[match.to...@line.length]

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
    pad = format("%0#{@pad_width}d: ", @line_number.to_s)
    @line.text = pad + @line.text
  end

  def output_line
    return unless @matches.first || @opts[:all_lines]
    @output.puts @line
  end
end
