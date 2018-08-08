require 'optparse'
require_relative './engine.rb'

module Rex
  class CLI
    def self.run
      options   = parse_options
      arguments = parse_arguments

      Engine.new(
        pattern:      arguments[:pattern],
        path:         arguments[:path],
        substitution: arguments[:substitution],
        user_options: options
      ).run
    end

    def self.parse_options
      options = {}

      option_parser = OptionParser.new do |opts|
        opts.banner = "Usage: rex [options] pattern path [substitution]"

        opts.on("--no-line-numbers", "Disable line numbers") do
          options[:line_numbers] = false
        end

        opts.on("--no-global-matching", "Disable global matching") do
          options[:global_matching] = false
        end

        opts.on("--non-matching-lines", "Output lines without matches") do
          options[:non_matching_lines] = true
        end

        opts.on("--only-matches", "Output matching segments only") do
          options[:only_matches] = true
        end
      end

      option_parser.parse!

      options
    end

    def self.parse_arguments
      {
        pattern:      ARGV.shift,
        path:         ARGV.shift,
        substitution: ARGV.shift
      }
    end
  end
end
