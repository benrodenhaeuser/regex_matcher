require 'colorize'

module Rex
  class Match
    attr_accessor :from
    attr_accessor :to

    def initialize(position)
      @from = position
      @to = nil
    end

    def found?
      @to
    end
  end

  class Line
    def initialize(text:, line_number:, substitution:)
      @text = text
      @line_number = line_number
      @substitution = substitution
      @position = 0
      @matches = []
    end

    def find_matches(automaton, global)
      @match = Match.new(@position)

      while cursor
        find_match(automaton)

        if @match.found?
          @matches << @match
          break unless global
        end

        @position = [@match.from + 1, @match.to].compact.max
        @match = Match.new(@position)
        automaton.reset
      end
    end

    def find_match(automaton)
      while automaton.step?(cursor)
        automaton.step!(cursor)
        consume
        @match.to = @position if automaton.terminal?
      end
    end

    def found_match?
      !@matches.empty?
    end

    def process_matches
      @matches.reverse.each do |match|
        process_match(match)
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

    def process_match(match)
      pre       = @text[0...match.from]
      the_match = @text[match.from...match.to]
      post      = @text[match.to...length]
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
