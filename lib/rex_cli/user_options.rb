require_relative './banner.rb'

module Rex
  module UserOptions
    def user_options
      options = {}

      option_parser = OptionParser.new do |opts|
        opts.banner = BANNER

        opts.on("--line-number=STATUS", "-l STATUS",
                "Print/hide *l*ine number (STATUS: on/off)") do |status|
          case status
          when 'on'  then options[:line_numbers] = true
          when 'off' then options[:line_numbers] = false
          end
        end

        opts.on("--file-name=STATUS", "-f STATUS",
                "print/hide *f*ile name (status: on/off)") do |status|
          case status
          when 'on'  then options[:file_names] = true
          when 'off' then options[:file_names] = false
          end
        end

        opts.on("--color=STATUS", "-c STATUS",
                "show/hide match *c*olor (status: on/off)") do |status|
          case status
          when 'on'  then options[:color] = true
          when 'off' then options[:color] = false
          end
        end

        opts.on("--git", "-g", "*g*it search") do
          options[:recursive] = true
          options[:git] = true

          git_dir = "git rev-parse --is-inside-work-tree 2>/dev/null"
          unless `#{git_dir}`.chomp == 'true'
            puts 'Not a git repository!'
            exit
          end
        end

        opts.on("--recursive", "-r", "*r*ecursive search") do
          options[:recursive] = true
        end

        opts.on("--single-match", "-s", "at most *s*ingle match per line") do
          options[:global] = false
        end

        opts.on("--all-lines", "-a", "output *a*ll input lines") do
          options[:all_lines] = true
        end

        opts.on("--only-match",
                "-o",
                "print *o*nly matches (not full lines)") do
          options[:only_matches] = true
        end

        opts.on("--whitespace", "-w", "leave leading *w*hitespace intact") do
          options[:whitespace] = true
        end

        opts.on_tail("--help", "Help (this message)") do
          puts opts
          exit
        end
      end

      option_parser.parse!
      options
    end
  end
end
