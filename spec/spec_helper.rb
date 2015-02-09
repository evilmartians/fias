$LOAD_PATH << '.' unless $LOAD_PATH.include?('.')

require 'rubygems'
require 'bundler/setup'
require 'simplecov'

SimpleCov.start do
  add_filter 'spec'
end

require 'fias/import'

RSpec.configure do |config|
  config.order = :random
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
end

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
