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
      arguments = {
        pattern: ARGV.shift,
        input:   Input.new(ARGV, options)
      }

      raise CliError, "You have to supply a pattern" unless arguments[:pattern]

      app = Application.new(
        pattern: arguments[:pattern],
        input:   arguments[:input],
        options: options
      )

      app.run!
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
