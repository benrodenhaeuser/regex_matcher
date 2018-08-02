require_relative 'set.rb'
require_relative 'parser.rb'
require_relative 'automaton.rb'

require 'colorize'

module Rex
  class Query
    attr_reader   :line
    attr_reader   :automaton
    attr_accessor :from
    attr_accessor :to
    attr_accessor :matches
    attr_accessor :global

    def initialize(line: nil, automaton: nil, global: false)
      @line = line
      @automaton = automaton
      @global = global

      scan!
      output!
    end

    def scan!
      @matches = []

      (0..@line.length).each do |index|
        @from = index
    		state = automaton.initial
        position = index

        while cursor = @line[position]
          unless state.moves[cursor]
            if match?
              @matches << @from << @to
              break unless @global # takes care of the single match per line situation
            end
            position += 1
            @from = position
            @to = nil
            cursor = @line[position]
            state = automaton.initial
            next
          end

          state = state.moves[cursor].elem
          @to = position if automaton.terminal.include?(state)
          position += 1
        end

        break unless @matches.empty?
      end
    end

    def output!
      return puts line if matches.empty?

      the_matches = matches.map.with_index do |elem, index|
        if index.even?
          if $stdout.isatty
            line[elem..matches[index + 1]].colorize(:light_green).underline # this would need to be different in the replace case.
          else
            line[elem..matches[index + 1]]
          end
        elsif matches[index + 1]
          line[matches[index] + 1...matches[index + 1]]
        else
          ''
        end
      end.join

      puts line[0...matches.first] + the_matches + line[matches.last + 1...line.length]
    end

    def match!
  	  (0..@line.length).each do |index|
        @from = index
    		state = automaton.initial
        position = index

    		while cursor = @line[position]
          break unless state.moves[cursor]
    			state = state.moves[cursor].elem
    			@to = position if automaton.terminal.include?(state)
    			position += 1
  		 	end

    		break if match?
  	  end
  	end

    def match?
      @from && @to
    end

    def match
      [@from, @to]
    end
  end

  class Matcher
    def initialize(pattern, path, substitution = nil)
      @pattern = pattern
      @path = path
      @substitution = substitution
    end

    def automaton
      @automaton ||= Parser.new(@pattern).parse.to_automaton.to_dfa
    end

    def scan
      file = File.open(@path)

      while line = file.gets
        Query.new(line: line, automaton: automaton, global: true)
      end

      file.close
    end

    def search
      file = File.open(@path)
      line_no = 0

      while line = file.gets
        line_no += 1
        @query = Query.new(line: line, automaton: automaton)
        puts_search_line(line_no) if @query.match?
      end

      file.close
    end

    def replace
      file = File.open(@path)

      while line = file.gets
        @query = Query.new(line, automaton)
        @query.match? ? puts_search_line : (puts line)
      end
    end

    def puts_search_line(line_no = nil)
      line = @query.line
      from = @query.from
      to =  @query.to

      pre = line[0...from]
      match = line[from..to]
      post = line[to + 1...line.length]

      match_output = @substitution ? @substitution : match

      if $stdout.isatty
        match_output = match_output.colorize(:light_green).underline
      end

      output_string = pre + match_output + post

      if line_no
        output_string = "#{pad(line_no)}:  " + output_string
      end

      puts output_string
    end

    # TODO readability
    # https://stackoverflow.com/questions/2650517
    def pad(number)
      line_count = %x{wc -l #{@path}}.split.first
      format("%0#{line_count.length}d", number.to_s)
    end
  end

  class CLI
    def self.run
      case ARGV.shift
      when 'search'
        pattern = ARGV.shift
        path = ARGV.shift
        Matcher.new(pattern, path).search
      when 'scan'
        pattern = ARGV.shift
        path = ARGV.shift
        Matcher.new(pattern, path).scan
      when 'replace'
        pattern = ARGV.shift
        substitution = ARGV.shift
        path = ARGV.shift
        Matcher.new(pattern, path, substitution).replace
      end
    end
  end
end
