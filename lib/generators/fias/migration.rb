module Fias
  class MigrationGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    class_option :prefix, type: :string, default: :fias, desc: 'Table names prefix'
    class_option :path, type: :string, default: 'tmp/fias', desc: 'Path to FIAS dbfs'
    class_option :only, type: :string, default: '', desc: 'Only tables'

    source_root File.expand_path("../templates", __FILE__)

    def generate_migration
      only = options.only.split(',').map(&:strip)
      wrapper = Fias::DbfWrapper.new(options.path)
      importer = Fias::Importer.build(prefix: options.prefix)

      tables = wrapper.tables(only)
      @schema = importer.schema(tables)
      @schema.gsub!("\n", "\n    ")

      migration_template 'create_fias_tables.rb', 'db/migrate/create_fias_tables'
    end

    def usage
      "Generates FIAS migrations for application"
    end

    # https://rails.lighthouseapp.com/projects/8994/tickets/3820-make-railsgeneratorsmigrationnext_migration_number-method-a-class-method-so-it-possible-to-use-it-in-custom-generators
    def self.next_migration_number(dirname)
      orm = Rails.configuration.generators.options[:rails][:orm]
      require "rails/generators/#{orm}"
      "#{orm.to_s.camelize}::Generators::Base".constantize.next_migration_number(dirname)
    end
  end
end