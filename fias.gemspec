# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fias/version'

Gem::Specification.new do |spec|
  spec.name          = 'fias'
  spec.version       = Fias::VERSION
  spec.authors       = ['Victor Sokolov']
  spec.email         = ['gzigzigzeo@evilmartians.com']
  spec.summary       = %q{Imports Russian FIAS database into SQL}
  spec.description   = %q{Imports Russian FIAS database into SQL (for Ruby on Rails on PostgreSQL projects)}
  spec.homepage      = 'shttp://github.com/evilmartians/fias'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'dbf'
  spec.add_dependency 'activesupport', '> 3'
  spec.add_dependency 'sequel'
  spec.add_dependency 'pg_data_encoder'
  spec.add_dependency 'httparty'
  spec.add_dependency 'pg'
  spec.add_dependency 'ruby-progressbar'
  spec.add_dependency 'unicode'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'codeclimate-test-reporter'
end
