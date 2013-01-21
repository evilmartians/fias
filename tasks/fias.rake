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
      wrapper = Fias::Import::DbfWrapper.new(fias_path)
      importer = wrapper.build_importer(prefix: ENV['PREFIX'])

      yield(wrapper, importer)
    end
  end

  desc 'Create FIAS tables (could specify tables PREFIX, PATH to dbfs and DATABASE_URL)'
  task may_be_rails(:create_tables) do
    within_connection do |wrapper, importer|
      ActiveRecord::Schema.define { eval(importer.schema) }
    end
  end

  namespace :import do
    desc 'Import FIAS data (without houses)'
    task may_be_rails(:placements) do
      within_connection do |wrapper, importer|
        total_record_count = wrapper.tables.sum { |accessor, dbf| dbf.record_count }

        puts 'Importing FIAS data...'

        bar = ProgressBar.new(total_record_count)
        importer.import do
          bar.increment!
        end
      end
    end

    desc 'Import FIAS data (houses)'
    task may_be_rails(:houses) do
      within_connection do |wrapper, importer|
        total_record_count = wrapper.houses.sum { |region, dbf| dbf.record_count }

        puts 'Importing FIAS data (houses)...'

        bar = ProgressBar.new(total_record_count)
        importer.import_houses do
          bar.increment!
        end
      end
    end
  end
end