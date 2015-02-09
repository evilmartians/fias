require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/slice'
require 'dbf'
require 'httparty'
require 'fias/import/version'
require 'fias/import/dbf'
require 'fias/import/schema'
require 'fias/import/download_service'

module Fias
  module Import
    DEFAULT_PREFIX = 'fias'
  end
end
