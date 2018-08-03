require_relative './set.rb'
require_relative './parser.rb'
require_relative './automaton.rb'

require 'colorize'

module Rex
  class Matcher
    attr_reader :matches

    def initialize(pattern:, path:, options: {})
      @pattern = pattern
      @path = path
      @substitution = options[:substitution]
      @global = options[:global]
      @line_numbers = options[:line_numbers]
      @non_matching = options[:non_matching]
    end

    def automaton
      @automaton ||= Parser.new(@pattern).parse.to_automaton.to_dfa
    end

    def match
      file = File.open(@path)

      @line_number = 1

      while @line = file.gets
        match_line
        output_line
        @line_number += 1
      end

      file.close
    end

    def match_line
      @matches = []
      @from = nil
      @to = nil

      (0..@line.length).each do |index|
        @from = index
        state = automaton.initial
        position = index

        while cursor = @line[position]
          if state.moves[cursor]
            state = state.moves[cursor].elem
            @to = position if automaton.terminal.include?(state)
            position += 1
          else
            if @from && @to
              @matches << @from << @to
              @to = nil
              break unless @global
              @from = position
              state = automaton.initial
            else
              position += 1
              @from = position
              state = automaton.initial
            end
          end
        end

        break unless @matches.empty?
      end
    end

    def output_line
      if @matches.empty?
        return unless @non_matching
        result_line = @line
      else
        the_matches = @matches.map.with_index do |elem, index|
          if index.even?
            if @substitution
              if $stdout.isatty
                @substitution.colorize(:light_green).underline
              else
                @substitution
              end
            else
              if $stdout.isatty # substitution (same logic again)
                @line[elem..@matches[index + 1]].colorize(:light_green).underline
              else
                @line[elem..@matches[index + 1]]
              end
            end
          elsif @matches[index + 1]
            @line[@matches[index] + 1...@matches[index + 1]]
          else
            ''
          end
        end.join

        result_line = @line[0...@matches.first] + the_matches + @line[@matches.last + 1...@line.length]
      end

      result_line = pad(@line_number) + result_line if @line_numbers

      puts result_line
    end

    # https://stackoverflow.com/questions/2650517
    def pad(number)
      line_count = %x{wc -l #{@path}}.split.first
      format("%0#{line_count.length}d:  ", number.to_s)
    end
  end
end
