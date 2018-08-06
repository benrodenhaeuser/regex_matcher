require_relative './parser.rb'
require_relative './automaton.rb'
require_relative './line.rb'

module Rex
  class Matcher
    DEFAULT_OPTIONS = {
      line_numbers:        true,
      global_matching:     true,
      output_non_matching: false
    }

    def initialize(pattern:, path:, substitution: nil, user_options: {})
      @pattern      = pattern
      @path         = path
      @substitution = substitution
      @opts         = DEFAULT_OPTIONS.merge(user_options)
    end

    def match
      file = File.open(@path)
      line_number = 1

      until file.eof?
        @line = Line.new(
          text:         file.gets,
          line_number:  line_number,
          substitution: @substitution
        )

        find_matches
        line.process_matches if line.found_match?
        line.prepend_line_number(line_count) if @opts[:line_numbers]
        line.output if line.found_match? || @opts[:output_non_matching]

        line_number += 1
      end

      file.close
    end

    private

    def automaton
      @automaton ||= Parser.new(@pattern).parse.to_automaton.to_dfa
    end

    def line
      @line
    end

    def line_count
      %x{wc -l #{@path}}.split.first
    end

    def find_matches
      (0..line.length).each do |index|
        find_matches_starting_at(index)
        break if line.found_match?
      end
    end

    def find_matches_starting_at(index)
      line.reset(index)

      while line.cursor
        if automaton.possible_step?(line.cursor)
          automaton.step(line.cursor)
          line.match! if automaton.terminal?
          line.consume
        else
          if line.match?
            line.save_match
            break unless @opts[:global_matching]
          else
            line.consume
          end

          line.reset
          automaton.reset
        end
      end
    end
  end
end
