module Rex
  class Line
    def initialize(text, line_number, substitution = nil)
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

    def found_match?
      !@matches.empty?
    end

    def output
      puts self
    end

    def process
      @matches.reverse.each do |match|
        substitute(match.first, match.last)
      end
    end

    private

    # TODO: unfortunate choice of name
    # TODO: @substitution and line numbers (pad method)
    def substitute(from, to)
      pre       = @text[0...from]
      the_match = @text[from..to]
      post      = @text[to + 1...length]

      the_match = the_match.colorize(:light_green).underline
      @text     = pre + the_match + post
    end

    # https://stackoverflow.com/questions/2650517
    def pad(number)
      line_count = %x{wc -l #{@path}}.split.first
      format("%0#{line_count.length}d:  ", number.to_s)
    end
  end
end
