module Rex
  module UserOptions
    BANNER = <<~HEREDOC
      rex finds and prints lines matching a pattern.

      Usage: rex [options] pattern [file ...]

      Defaults:
          - print line numbers if (and only if) reading input from a file
          - show file names if (and only if) searching multiple files
          - colorize matches if (and only if) printing to terminal
          - find multiple matches per line
          - print lines with matches only
          - print lines rather than only matches
          - strip leading whitespace from lines printed
          - non-recursively search given files

      Notes:
          - use `--filename on/off`, `--line-number on/off` and `--color
            on/off` options to override the 'smart' defaults described above
          - use `rex --recursive pattern` to recursively search files in current
            working directory
          - use `rex --git pattern` to recursively search files in current
            working directory while honouring their 'git ignore' status
          - works like standard UNIX tools:
            - `rex [options] pattern` will have rex read from stdin
            - `cmd | rex ...` will pipe cmd output to rex input
            - `rex ... | cmd` will pipe rex output to cmd input
            - `rex ... > file` will write rex output to file

      Options:
    HEREDOC

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
