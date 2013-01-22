# encoding: utf-8
module Fias
  class AddressObjectType < ActiveRecord::Base
    # TODO: Тут надо понять как префикс передать
    if defined?(Rails)
      self.table_name = "#{Rails.application.config.fias.prefix}_address_object_types"
    else
      self.table_name = "fias_address_object_types"
    end
    self.primary_key = 'scname'

    alias_attribute :name, :socrname
    alias_attribute :abbrevation, :scname
  end
end