require 'fias'

namespace :fias do
  class << self
    private
    # Если гем используется внутри рельсов - стоит загрузить энвайронмент
    # и подключиться к БД.
    def may_be_rails(name)
      defined?(Rails) ? {name => :environment} : name
    end

    # Открывает DBFы ФИАС, соединяется с базой и передает все это блоку
    def within_connection(&block)
      require 'active_record'
      require 'progress_bar'

      begin
        ActiveRecord::Base.connection
      rescue ActiveRecord::ConnectionNotEstablished
        if ENV['DATABASE_URL'].nil?
          raise ArgumentError, 'Specify database in DATABASE_URL env variable'
        end

        ActiveRecord::Base.establish_connection
      end

      fias_path = ENV['FIAS'] || 'tmp/fias'
      wrapper = Fias::DbfWrapper.new(fias_path)
      importer = Fias::Importer.build(prefix: ENV['PREFIX'])

      yield(wrapper, importer)
    end

    def only
      only = ENV['ONLY'].to_s.split(',').map(&:strip)
    end
  end

  desc 'Create FIAS tables (could specify tables PREFIX, PATH to dbfs and DATABASE_URL, EXCLUDE or ONLY tables)'
  task may_be_rails(:create_tables) do
    within_connection do |wrapper, importer|
      tables = wrapper.tables(only)
      # TODO: Добавить во враппер tables, это убрать
      raise "DBF file not found for: #{key}" if tables.keys.any? { |key| key.nil? }
      ActiveRecord::Schema.define do
        eval(importer.schema(tables))
      end
    end
  end

  desc 'Import FIAS data'
  task may_be_rails(:import) do
    within_connection do |wrapper, importer|
      tables = wrapper.tables(only)

      total_record_count = tables.sum do |accessor, dbf|
        dbf.present? ? dbf.record_count : 0
      end

      puts 'Importing FIAS data...'

      bar = ProgressBar.new(total_record_count)
      importer.import(tables) do
        bar.increment!
      end
    end
  end
end