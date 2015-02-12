$LOAD_PATH << '.' unless $LOAD_PATH.include?('.')

require 'rubygems'
require 'bundler/setup'
require 'simplecov'
require 'webmock/rspec'
require 'sequel'

SimpleCov.start do
  add_filter 'spec'
end

if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

require 'fias'

WebMock.disable_net_connect!(allow: %w(codeclimate.com))

RSpec.configure do |config|
  config.order = :random
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
end

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
