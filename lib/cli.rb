require 'optparse'
require_relative './application.rb'

module Rex
  class CliError < RuntimeError; end

  class CLI
    def self.run
      options   = parse_options
      arguments = parse_arguments

      raise CliError, "You have to supply a pattern" unless arguments[:pattern]

      Application.new(
        pattern:      arguments[:pattern],
        input:        arguments[:input],
        user_options: options
      ).run
    end

    def self.parse_options
      options = {}

      option_parser = OptionParser.new do |opts|
        opts.banner = "Usage: rex [options] pattern input-path [output-path]"

        opts.on("--disable-line-numbers", "-d", "Disable line numbers") do
          options[:line_numbers] = false
        end

        opts.on("--one-match", "-o", "One match per line") do
          options[:global] = false
        end

        opts.on("--all-lines", "-a", "All input lines") do
          options[:all_lines] = true
        end

        opts.on("--matching-segments-only", "-m", "Matching segments only") do
          options[:only_matches] = true
        end
      end

      option_parser.parse!

      options
    end

    private_class_method :parse_options

    def self.parse_arguments
      {
        pattern: ARGV.shift,
        input:   ARGF
      }
    end

    private_class_method :parse_arguments
  end
end
