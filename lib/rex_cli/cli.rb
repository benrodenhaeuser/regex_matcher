require 'optparse'
require_relative './application.rb'
require_relative './input.rb'

module Rex
  class CliError < RuntimeError; end

  class CLI
    def self.run
      handle_sigint

      ARGV << '--help' if ARGV.empty?

      options   = parse_options
      arguments = parse_arguments

      raise CliError, "You have to supply a pattern" unless arguments[:pattern]

      app = Application.new(
        pattern:      arguments[:pattern],
        input:        arguments[:input],
        user_options: options
      )

      app.report!
    end

    def self.parse_arguments
      {
        pattern: ARGV.shift,
        input:   Input[*ARGV]
      }
    end

    private_class_method :parse_arguments

    def self.handle_sigint
      trap "SIGINT" do
        puts; puts "Good-bye"
        exit!
      end
    end

    private_class_method :handle_sigint

    BANNER = <<~HEREDOC
      Usage: rex [options] pattern [file(s)]

      Defaults:
          - prints line numbers
          - finds multiple matches per line ('global' matching)
          - prints lines with matches only
          - prints whole lines (rather than only matching segments)
          - strips leading whitespace
          - highlights matches, but only when printing to terminal
          - shows file names, but only when searching multiple files

      Notes:
          - rex reads from stdin when `file(s)` argument is absent
          - if provided, `file(s)` is overwritten when `--git` switch is set
          - rex prints start column for matches when `-m` switch is set

      Options:
    HEREDOC

    def self.parse_options
      options = {}

      option_parser = OptionParser.new do |opts|
        opts.banner = BANNER

        opts.on("--disable-linenos", "-d",
                "*D*isable line numbers") do
          options[:line_numbers] = false
        end

        opts.on("--git", "-g",
                "Search current *g*it repository") do
          options[:git] = true
        end

        opts.on("--one-match", "-o",
                "At most *o*ne match per line of input") do
          options[:global] = false
        end

        opts.on("--all-lines", "-a",
                "Output *a*ll input lines") do
          options[:all_lines] = true
        end

        opts.on("--matching-only", "-m",
                "Output *m*atching line segments only") do
          options[:only_matches] = true
        end

        opts.on("--whitespace", "-w",
                "Leave leading *w*hitespace intact") do
          options[:whitespace] = true
        end

        opts.on("--highlight", "-h",
                "Enforce *h*ighlighting") do
          options[:highlight] = true
        end

        opts.on("--file-names", "-f",
                "Enforce *f*ile name output") do
          options[:file_names] = true
        end

        opts.on_tail("--help",
                     "Help (this message)") do
          puts opts
          exit
        end
      end

      option_parser.parse!

      options
    end

    private_class_method :parse_options
  end
end
