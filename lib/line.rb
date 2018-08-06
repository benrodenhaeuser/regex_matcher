require 'colorize'

module Rex
  class Line
    def initialize(text:, line_number: nil, substitution: nil)
      @text = text
      @line_number = line_number
      @substitution = substitution
      @matches = []
    end

    def reset(index = @position)
      @position = index
      @from = @position
      @to = nil
    end

    def length
      @text.length
    end

    def to_s
      @text
    end

    def cursor
      @text[@position]
    end

    def consume
      @position += 1
    end

    def [](index)
      @text[index]
    end

    def match?
      @from && @to
    end

    def match
      [@from, @to]
    end

    def match!
      @to = @position
    end

    def save_match
      @matches << match
    end

    def prepend_line_number(line_count)
      pad = format("%0#{line_count.length}d:  ", @line_number.to_s)
      @text = pad + @text
    end

    def found_match?
      !@matches.empty?
    end

    def output
      puts self
    end

    def process_matches
      @matches.reverse.each do |match|
        process_match(match.first, match.last)
      end
    end

    private

    def process_match(from, to)
      pre       = @text[0...from]
      the_match = @text[from..to]
      post      = @text[to + 1...length]
      @text     = pre + replace(the_match) + post
    end

    def replace(the_match)
      if tty? && @substitution
        @substitution.colorize(:light_green).underline
      elsif tty?
        the_match.colorize(:light_green).underline
      elsif @substitution
        @substitution
      else
        the_match
      end
    end

    def tty?
      $stdout.isatty
    end
  end
end
