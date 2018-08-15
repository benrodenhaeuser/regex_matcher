require 'rake'

Gem::Specification.new do |s|
  s.name        = 'rex_cli'
  s.version     = '0.1.0'
  s.licenses    = ['MIT']
  s.summary     = "A regular expression engine wrapped in a command line interface"
  s.description = "Rex is a regular expression engine based on finite state automata with a command line interface in the style of grep."
  s.authors     = ["Ben Rodenhäuser"]
  s.email       = 'ben@rodenhaeuser.de'
  s.files       = FileList[
                            'lib/rex_cli.rb',
                            'lib/rex_cli/*',
                            'test/*.rb',
                            'Rakefile',
                            'Gemfile',
                            'rex_cli.gemspec',
                            'README.md'
                          ].to_a
  s.executables = ['rex']
  s.homepage    = 'https://rubygems.org/gems/rex_cli'
  s.metadata    = { "source_code_uri" => "https://github.com/benrodenhaeuser/rex" }
end
