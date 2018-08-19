require 'optparse'
require_relative './options.rb'
require_relative './application.rb'
require_relative './input.rb'

module Rex
  class CliError < RuntimeError; end

  class CLI
    extend Options

    def self.run
      trap_sigint

      ARGV << '--help' if ARGV.empty?

      options = parse_options
      arguments = parse_arguments(options)

      raise CliError, "You have to supply a pattern" unless arguments[:pattern]

      app = Application.new(
        pattern: arguments[:pattern],
        input:   arguments[:input],
        options: options
      )

      app.run!
    end

    def self.parse_arguments(options)
      {
        pattern: ARGV.shift,
        input:   Input.new(ARGV, options)
      }
    end

    def self.trap_sigint
      trap "SIGINT" do
        puts; puts "Good-bye"
        exit!
      end
    end

    private_class_method :trap_sigint
    private_class_method :parse_arguments
    private_class_method :parse_options
  end
end
