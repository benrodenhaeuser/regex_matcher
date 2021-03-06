require_relative 'lib/rex_cli/colored_string'
require 'bundler/gem_tasks'

# - runs all test files in `test`
# - logs minitest output to `test/reports`
# - prints per file summary (failures/errors/skips)

desc 'Run all tests'
task :test do
  run_tests
end

def run_tests
  Dir.mkdir('test/reports') unless Dir.exist?('test/reports')

  test_path = "test/%{fn}"
  report_path = "test/reports/%{fn}"

  headline = ">>> #{test_path}".color(:red)
  run = "ruby #{test_path} | tee #{report_path}.txt"
  exp =
    "(0|1|2|3|4|5|6|7|8|9)* failures, " +
    "(0|1|2|3|4|5|6|7|8|9)* errors, " +
    "(0|1|2|3|4|5|6|7|8|9)* skips"

  res = "bin/rex --line-number off --color off -o '%{exp}' ./#{report_path}.txt"

  summary = test_files.each_with_object('') do |fn, summary|
    puts headline % { fn: fn}
    system "#{run % { fn: fn }}"
    puts

    summary << "#{fn}: " + `#{res % { fn: fn, exp: exp }}`
  end

  puts ">>> summary".color(:red)
  puts summary
end

def test_files
  Dir.entries('./test')
     .select { |file| File.file?(File.expand_path(file, 'test')) }
     .select { |file| file.include?('test') }
end

desc 'Run all tests'
task :default => :test
