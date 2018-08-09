require 'optparse'
require_relative './engine.rb'

module Rex
  class CLI
    def self.run
      options   = parse_options
      arguments = parse_arguments

      Engine.new(
        pattern:      arguments[:pattern],
        in_path:      arguments[:in_path],
        out_path:     arguments[:out_path],
        user_options: options
      ).run
    end

    def self.parse_options
      options = {}

      option_parser = OptionParser.new do |opts|
        opts.banner = "Usage: rex [options] pattern input-path [output-path]"

        opts.on("--substitution SUBSTITUTION", "-s SUBSTITUTION", "substitute matches with value") do |value|
          options[:substitution] = value
        end

        opts.on("--disable-line-numbers", "-d", "Disable line numbers") do
          options[:line_numbers] = false
        end

        opts.on("--one-match", "-o", "One match per line") do
          options[:one_match_per_line] = true
        end

        opts.on("--all-lines", "-a", "Output all input lines") do
          options[:all_lines] = true
        end

        opts.on("--matching-segments-only", "-m", "Output matching segments only") do
          options[:matching_segments_only] = true
        end
      end

      option_parser.parse!

      options
    end

    def self.parse_arguments
      {
        pattern:  ARGV.shift,
        in_path:  ARGV.shift,
        out_path: ARGV.shift
      }
    end
  end
end
