require_relative './line.rb'
require_relative './match.rb'

module Rex
  class Matcher
    def initialize(automaton, local)
      @automaton = automaton
      @global = !local
    end

    def match(text)
      @line = Line.new(text)
      scan_line
      { line: @line, matches: @matches }
    end

    private

    def scan_line
      @matches = []

      loop do
        break unless @line.cursor
        @match = Match.new(@line.position)
        @automaton.reset

        find_match

        if @match.found?
          @matches << @match
          break unless @global
        end

        @line.position = [@match.from + 1, @match.to].compact.max
      end
    end

    def find_match
      loop do
        @match.to = @line.position if @automaton.terminal?
        break unless @automaton.step?(@line.cursor)
        @automaton.step!(@line.cursor)
        @line.consume
      end
    end
  end
end
