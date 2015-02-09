require 'fias/import'

namespace :fias do
  desc 'Create FIAS tables (PREFIX, FIAS_PATH to dbfs, DATABASE_URL, and TABLES)'
  task :create_tables do
    within_connection do |files|
      schema = Fias::Import::Schema.new(files)

      ActiveRecord::Schema.define do
        eval(schema.schema)
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
    files = Fias::Import::Dbf.new(fias_path).only(ENV['TABLES'] || [])

    yield(files)
  end
end