# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fias/version'

Gem::Specification.new do |gem|
  gem.name          = "fias"
  gem.version       = Fias::VERSION
  gem.authors       = ["Victor Sokolov"]
  gem.email         = ["gzigzigzeo@evilmartians.com"]
  gem.description   = %q{Ruby wrapper to FIAS database}
  gem.summary       = %q{Ruby wrapper to FIAS database}
  gem.homepage      = "http://github.com/evilmartians/fias"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'dbf'
  gem.add_dependency 'rake'
  gem.add_dependency 'activerecord', '> 3'
  gem.add_dependency 'progress_bar'
  gem.add_development_dependency 'pg'
  gem.add_development_dependency 'sqlite3'
end