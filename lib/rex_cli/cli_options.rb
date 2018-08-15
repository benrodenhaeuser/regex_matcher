module Rex
  module CliOptions
    BANNER = <<~HEREDOC
      rex prints lines that contain a match for a pattern (like grep).

      Usage: rex [options] pattern [file(s)]

      Defaults:
          - prints line numbers
          - finds multiple matches per line ('global' matching)
          - prints lines with matches only
          - prints whole lines (rather than only matching segments)
          - strips leading whitespace
          - highlights matches, but only if printing to terminal
          - shows file names, but only if searching multiple files

      Notes:
          - if `--git` is set, rex searches the files currently under git
            source control (as of last commit)
          - if `file(s)` argument is absend (and `--git` not set), rex reads
            from stdin
          - rex will print start column of each match if `-m` switch is set

      Options:
    HEREDOC

    def parse_options
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
  end
end
