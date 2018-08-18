module Rex
  module CliOptions
    BANNER = <<~HEREDOC
      rex prints lines that contain a match for a pattern (like grep).

      Usage: rex [options] pattern [file ...]

      Defaults:
          - prints line numbers (if reading input from a file)
          - finds multiple matches per line
          - prints match-containing lines only
          - prints whole lines (rather than only matches)
          - strips leading whitespace from lines
          - visually highlights matches (if printing to terminal)
          - shows file names (if searching multiple files)

      Notes:
          - use `rex --git pattern` to search files under git source control
          - as usual:
            - `rex [options] pattern` will have rex read from stdin
            - `cmd | rex ...` will pipe cmd output to rex input
            - `rex ... | cmd` will pipe rex output to cmd input
            - `rex ... > file` will write rex output to file

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

        opts.on("--highlight", "-H",
                "Enforce *h*ighlighting") do
          options[:highlight] = true
        end

        opts.on("--nohighlight", "-h",
                "Disable *h*ighlighting") do
          options[:highlight] = false
        end

        opts.on("--file-names", "-f",
                "Enforce *f*ile name output") do
          options[:file_names] = true
        end

        opts.on("--recursive", "-r", "recursive search") do
          options[:recursive] = true
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
