require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/slice'
require 'dbf'
require 'httparty'
require 'pg_data_encoder'
require 'fias/import/version'
require 'fias/import/dbf'
require 'fias/import/schema'
require 'fias/import/download_service'
require 'fias/import/copy'
require 'fias/railtie' if defined?(Rails)

module Fias
  module Import
  end
end
