require_relative './parser.rb'
require_relative './automaton.rb'
require_relative './line.rb'

module Rex
  class Engine
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

    def run
      file = File.open(@path)
      line_number = 1

      until file.eof?
        @line = Line.new(
          text:         file.gets.chomp,
          line_number:  line_number,
          substitution: @substitution
        )

        @line.find_matches(automaton.reset, @opts[:global_matching])
        @line.process_matches if @line.found_match?
        @line.prepend_line_number(line_count) if @opts[:line_numbers]
        @line.output if @line.found_match? || @opts[:output_non_matching]

        line_number += 1
      end

      file.close
    end

    private

    def automaton
      @automaton ||= Parser.new(@pattern).parse.to_automaton.to_dfa
    end

    def line_count
      @line_count ||= %x{wc -l #{@path}}.split.first
    end
  end
end
