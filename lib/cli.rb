require_relative './matcher.rb'

module Rex
  class CLI
    SEARCH_OPTS = {
      line_numbers: true,
      global: false,
      non_matching: false
    }

    SCAN_OPTS = {
      line_numbers: true,
      global: true,
      non_matching_lines: false
    }

    REPLACE_OPTS = {
      line_numbers: false,
      global: true,
      non_matching_lines: true
    }

    def self.run
      case ARGV.shift
      when 'search'
        pattern = ARGV.shift
        path = ARGV.shift
        Matcher.new(pattern, path).search
      when 'scan'
        pattern = ARGV.shift
        path = ARGV.shift
        Matcher.new(pattern, path).match
      when 'replace'
        pattern = ARGV.shift
        substitution = ARGV.shift
        path = ARGV.shift
        Matcher.new(pattern, path, substitution).replace
      end
    end
  end
end
