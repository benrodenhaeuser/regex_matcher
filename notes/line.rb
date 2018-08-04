require 'colorize'

def substitute(line, from, to, substitution)
  pre = line[0...from]
  post = line[to + 1...line.length]
  [pre, substitution, post].join
end

line = 'abcde'
puts substitute(line, 1, 3, 'D'.colorize(:light_green).underline)
