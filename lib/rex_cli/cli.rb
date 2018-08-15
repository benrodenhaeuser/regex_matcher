require 'optparse'
require_relative './cli_options.rb'
require_relative './application.rb'
require_relative './input.rb'

module Rex
  class CliError < RuntimeError; end

  class CLI
    extend CliOptions

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

    def self.handle_sigint
      trap "SIGINT" do
        puts; puts "Good-bye"
        exit!
      end
    end

    private_class_method :handle_sigint
    private_class_method :parse_arguments
    private_class_method :parse_options
  end
end
