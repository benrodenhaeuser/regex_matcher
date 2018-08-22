module Rex
  module UserOptions
    BANNER = <<~HEREDOC
      rex finds matches for a pattern.

      Usage: rex [options] pattern [file ...]

      Defaults:
          - print line numbers iff reading input from a file
          - show file names iff searching multiple files
          - colorize matches iff printing to terminal
          - find multiple matches per line
          - print lines with matches only
          - print lines rather than only matches
          - strip leading whitespace from lines printed
          - non-recursively search given files

      Notes:
          - use `--line-number`, `--filename` and `--color` flags to override
            'smart' defaults described above
          - use `rex --recursive pattern` to recursively search files in current
            working directory
          - use `rex --git pattern` to recursively search files in current
            working directory while honouring their 'git ignore' status
          - the following will work as usual:
            - `rex pattern`    (omit file argument to use terminal as rex input)
            - `cmd | rex ...`  (pipe cmd output to rex input)
            - `rex ... | cmd`  (pipe rex output to cmd input)
            - `rex ... > file` (redirect rex output to file)

      Options:
    HEREDOC
  end
end
