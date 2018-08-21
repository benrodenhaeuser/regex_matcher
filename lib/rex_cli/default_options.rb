module Rex
  DEFAULT_OPTIONS = {             # corresponding flag:
    git:            false,        # `-g`
    recursive:      false,        # `-r`
    global:         true,         # `-s`
    all_lines:      false,        # `-a`
    only_matches:   false,        # `-o`
    whitespace:     false,        # `-w`
    skip_dot_files: true,         # (no flag)
    line_numbers:   nil,          # `-l ARG`
    color:          nil,          # `-c ARG`
    file_names:     nil           # `-f ARG`
  }.freeze
end
