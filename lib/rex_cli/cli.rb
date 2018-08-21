require 'optparse'
require_relative './user_options.rb'
require_relative './application.rb'
require_relative './input.rb'
require_relative './defaults.rb'

module Rex
  class CliError < RuntimeError; end

  class CLI
    extend UserOptions

    def self.run
      trap_sigint

      ARGV << '--help' if ARGV.empty?
      options = DEFAULT_OPTIONS.merge(user_options)
      raise CliError, "You have to supply a pattern" if ARGV.empty?

      Application.new(
        pattern: ARGV.shift,
        input:   Input.new(ARGV, options),
        options: options
      ).run!
    end

    def self.trap_sigint
      trap "SIGINT" do
        puts; puts "Good-bye"
        exit!
      end
    end

    private_class_method :trap_sigint
  end
end
