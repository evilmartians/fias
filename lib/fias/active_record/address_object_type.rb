module Fias
  class AddressObjectType < ActiveRecord::Base
    self.table_name = "#{Rails.application.config.fias.prefix}_fias_address_object_types"
    self.primary_key = 'scname'

    alias_attribute :name, :socrname
  end
end