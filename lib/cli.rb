require_relative './engine.rb'

module Rex
  class CLI
    class << self
      def run
        return puts help_message unless ARGV[0] && ARGV[1]
        match = Engine.new(ARGV[0], ARGV[1]).match?
        puts (match ? 'matched' : 'no match')
      end

      def help_message
        "You must provide a pattern and a string to search."
      end
    end
  end
end
