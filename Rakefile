require_relative 'lib/rex_cli/highlighted_string'
require 'bundler/gem_tasks'

# runs all files in `test` directory whose name includes `test`
# minitest output is logged to `test/reports`
# displays a summary report after all tests have run
desc 'Run all tests'
task :test do
  run_tests
end

def run_tests
  Dir.mkdir('test/reports') unless Dir.exist?('test/reports')

  run_tests = "ruby test/%{filename} | tee test/reports/%{filename}.txt"
  regex =
    "(0|1|2|3|4|5|6|7|8|9)* failures, " +
    "(0|1|2|3|4|5|6|7|8|9)* errors"
  rex = "bin/rex -fdh '%{regex}' ./test/reports/%{filename}.txt"
  headline = ">>> test/%{filename}".highlight(:red)

  summary = test_files.each_with_object('') do |filename, summary|
    puts headline % { filename: filename}
    system "#{run_tests % { filename: filename }}"
    puts
    summary << `#{rex % { filename: filename, regex: regex }}`
  end

  puts ">>> summary".highlight(:red)
  puts summary
end

def test_files
  Dir.entries('./test')
     .select { |file| File.file?(File.expand_path(file, 'test')) }
     .select { |file| file.include?('test') }
end

desc 'Run all tests'
task :default => :test
