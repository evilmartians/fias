require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/slice'
require 'dbf'
require 'httparty'
require 'pg_data_encoder'
require 'fias/version'
require 'fias/import/dbf'
require 'fias/import/tables'
require 'fias/import/download_service'
require 'fias/import/copy'
require 'fias/import/tree_builder'
require 'fias/railtie' if defined?(Rails)

module Fias
end
