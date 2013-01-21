module Fias
  class Railtie < Rails::Railtie
    config.fias = ActiveSupport::OrderedOptions.new
    config.fias.prefix = 'fias'
    config.app_generators.orm :active_record

    generators do
      require 'generators/fias/migration'
    end

    rake_tasks do
      load File.join(File.dirname(__FILE__), '../../tasks/fias.rake')
    end

    initializer 'fias.load_models' do
      ActiveSupport.on_load(:active_record) do
        require 'fias/active_record/address_object'
        require 'fias/active_record/address_object_type'
      end
    end
  end
end