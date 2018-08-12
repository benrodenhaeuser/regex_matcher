require_relative './parser.rb'
require_relative './line.rb'
require_relative './match.rb'
require_relative './search_result.rb'

module Rex
  class Engine
    def initialize(pattern, opts)
      @automaton   = Parser.new(pattern).parse.to_automaton.to_dfa
      @opts        = opts
      @line_number = 0
    end

    def search(text)
      @line_number += 1
      matches = find_matches(text)
      SearchResult.new(text, @line_number, matches)
    end

    private

    def find_matches(text)
      matches = []
      line = Line.new(text)

      loop do
        break unless line.cursor
        match = Match.new(line.position)
        @automaton.reset

        seek(match, line)

        if match.found?
          matches << match
          break unless @opts[:global]
        end

        line.position = [match.from + 1, match.to].compact.max
      end

      matches
    end

    def seek(match, line)
      loop do
        match.to = line.position if @automaton.terminal?
        break unless @automaton.step?(line.cursor)
        @automaton.step!(line.cursor)
        line.consume
      end
    end
  end
end
