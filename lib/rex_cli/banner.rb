module Rex
  module UserOptions
    BANNER = <<~HEREDOC
      rex finds matches for a pattern.

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
  end
end
