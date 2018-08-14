require "rake/testtask"

desc 'Run tests'
task :test do
  run_tests
end

desc 'Run tests'
task :default => :test

def run_tests
  test_files.each do |filename|
    `ruby test/#{filename} > test/reports/#{filename}.txt`
    puts `bin/rex -fdh '(0|1|2|3|4|5|6|7|8|9)* failures' ./test/reports/#{filename}.txt`
  end
end

def test_files
  Dir.entries('./test').select { |file| File.file?(File.expand_path(file, 'test')) }
end
