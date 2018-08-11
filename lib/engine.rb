require_relative './parser.rb'
require_relative './line.rb'
require_relative './match.rb'

module Rex
  class Engine
    def initialize(pattern, global)
      @automaton   = Parser.new(pattern).parse.to_automaton.to_dfa
      @global      = global
      @line_number = 0
    end

    def match(text)
      @line = Line.new(text, @line_number += 1)
      find_matches
      @line
    end

    private

    def find_matches
      loop do
        break unless @line.cursor
        @match = Match.new(@line.position)
        @automaton.reset

        find_next_match

        if @match.found?
          @line.matches << @match
          break unless @global
        end

        @line.position = [@match.from + 1, @match.to].compact.max
      end
    end

    def find_next_match
      loop do
        @match.to = @line.position if @automaton.terminal?
        break unless @automaton.step?(@line.cursor)
        @automaton.step!(@line.cursor)
        @line.consume
      end
    end
  end
end
