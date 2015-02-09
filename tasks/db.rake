require 'fias/import'
require 'ruby-progressbar'

namespace :fias do
  desc 'Create FIAS tables (PREFIX, FIAS_PATH to dbfs, DATABASE_URL and TABLES)'
  task :create_tables do
    within_connection do |schema|
      ActiveRecord::Schema.define { eval(schema.schema) }
    end
  end

  desc 'Import FIAS data (PREFIX, FIAS_PATH to dbfs, DATABASE_URL and TABLES)'
  task :import do
    within_connection do |schema|
      schema.tables.each do |table|
        puts "Encoding #{table.table_name}..."
        bar = ProgressBar.create(
          total: table.dbf.record_count,
          format: '%a |%B| [%E] (%c/%C) %p%%'
        )

        table.encode { bar.increment }
        table.perform
      end
    end
  end

  private

  def connect_db
    require 'active_record'

    begin
      ActiveRecord::Base.connection
    rescue ActiveRecord::ConnectionNotEstablished
      if ENV['DATABASE_URL'].blank?
        fail ArgumentError, 'Specify database in DATABASE_URL env variable or call rake environment [task]'
      end
      ActiveRecord::Base.establish_connection
    end
  end

  def within_connection(&block)
    connect_db

    fias_path = ENV['FIAS_PATH'] || 'tmp/fias'
    files = Fias::Import::Dbf.new(fias_path).only(
      *ENV['TABLES'].to_s.split(',')
    )
    schema = Fias::Import::Schema.new(files)

    yield(schema)
  end
end