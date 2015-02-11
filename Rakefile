require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
load 'tasks/download.rake'
load 'tasks/db.rake'

RSpec::Core::RakeTask.new(:spec)
task :default => :spec