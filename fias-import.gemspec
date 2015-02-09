# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fias/import/version'

Gem::Specification.new do |spec|
  spec.name          = 'fias-import'
  spec.version       = Fias::Import::VERSION
  spec.authors       = ['Victor Sokolov']
  spec.email         = ['gzigzigzeo@evilmartians.com']
  spec.summary       = %q{Imports FIAS database into SQL}
  spec.description   = %q{Imports FIAS database into SQL}
  spec.homepage      = 'http://github.com/gzigzigzeo/fias-import'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'dbf'
  spec.add_dependency 'activesupport', '> 3'
  spec.add_dependency 'activerecord', '> 3'
  spec.add_dependency 'pg_data_encoder'
  spec.add_dependency 'httparty'
  spec.add_dependency 'pg'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'webmock'
end
