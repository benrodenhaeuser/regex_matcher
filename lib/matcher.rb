require_relative './parser.rb'
require_relative './automaton.rb'
require_relative './line.rb'

require 'colorize'

module Rex
  class Matcher
    def initialize(pattern:, path:, opts: {})
      @pattern   = pattern
      @path      = path
      @opts      = opts
    end

    def match
      file = File.open(@path)
      line_number = 1

      until file.eof?
        @line = Line.new(file.gets, line_number, @opts[:substitution])

        find_matches

        if line.saved_match? && (stdout_is_tty? || @opts[:substitution])
          line.process_matches
        end

        if line.saved_match? || @opts[:output_non_matching]
          line.output
        end

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

    def find_matches
      (0..line.length).each do |index|
        find_matches_starting_at(index)
        break if line.saved_match?
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

    def stdout_is_tty?
      $stdout.isatty
    end
  end
end
