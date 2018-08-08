require 'colorize'

module Rex
  class Line
    def initialize(text:, line_number:, substitution:)
      @text = text
      @line_number = line_number
      @substitution = substitution
      @matches = []
    end

    def find_matches(automaton, global)
      setup(0) # intransparent naming

      while cursor
        match = find_match(automaton)

        if match
          @matches << match
          break unless global
        end

        setup([@from + 1, @to].compact.max)
        automaton.reset
      end
    end

    def find_match(automaton)
      while automaton.step?(cursor)
        automaton.step!(cursor)
        consume
        @to = @position if automaton.terminal?
      end
      @to ? [@from, @to] : nil
    end

    def found_match?
      !@matches.empty?
    end

    def process_matches
      @matches.reverse.each do |match|
        process_match(match.first, match.last)
      end
    end

    def prepend_line_number(line_count)
      pad = format("%0#{line_count.length}d:  ", @line_number.to_s)
      @text = pad + @text
    end

    def output
      puts self
    end

    def to_s
      @text
    end

    private

    def length
      @text.length
    end

    def cursor
      @text[@position]
    end

    def consume
      @position += 1
    end

    def setup(index)
      @position = index
      @from = @position
      @to = nil
    end

    def process_match(from, to)
      pre       = @text[0...from]
      the_match = @text[from...to]
      post      = @text[to...length]
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
