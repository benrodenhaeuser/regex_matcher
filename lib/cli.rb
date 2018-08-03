require_relative './matcher.rb'

module Rex
  class CLI
    SEARCH_OPTS = {
      line_numbers: false,
      global: false,
      non_matching: false
    }

    SCAN_OPTS = {
      line_numbers: true,
      global: true,
      non_matching: false
    }

    REPLACE_OPTS = {
      line_numbers: false,
      global: true,
      non_matching: true
    }

    def self.run
      case ARGV.shift
      when 'search'
        pattern = ARGV.shift
        path = ARGV.shift
        Matcher.new(
          pattern: pattern,
          path: path,
          options: SEARCH_OPTS
        ).match
      when 'scan'
        pattern = ARGV.shift
        path = ARGV.shift
        Matcher.new(
          pattern: pattern,
          path: path,
          options: SCAN_OPTS
        ).match
      when 'replace'
        pattern = ARGV.shift
        substitution = ARGV.shift
        path = ARGV.shift
        opts = { substitution: substitution}.merge!(REPLACE_OPTS)
        Matcher.new(
          pattern: pattern,
          path: path,
          options: opts
        ).match
      end
    end
  end
end
