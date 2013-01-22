require 'dbf'

require 'active_record'

require 'fias/version'
require 'fias/dbf_wrapper'
require 'fias/importer'
require 'fias/importer/base'
require 'fias/importer/pg'
require 'fias/importer/sqlite'

require 'fias/railtie' if defined?(Rails)

module Fias
end