require 'fias'
require 'ruby-progressbar'
require 'sequel'

namespace :fias do
  desc 'Create FIAS tables (PREFIX, FIAS_PATH to dbfs, DATABASE_URL and TABLES)'
  task :create_tables do
    within_connection do |tables|
      tables.create
      puts "#{tables.files.keys.join(', ')} created."
    end
  end

  desc 'Import FIAS data (PREFIX, FIAS_PATH to dbfs, DATABASE_URL and TABLES)'
  task :import do
    within_connection do |tables|
      db = Sequel.connect(ENV['DATABASE_URL'])
      ordered_presented_tables =
         tables.copy.map(&:table_name).select do |table_name|
            db.table_exists? table_name
         end

      border_index = 0

      ordered_presented_tables.reverse.each do |table|
        break if db[table].count > 0
        border_index = ordered_presented_tables.index table
      end

      tables.copy.each do |table|
        next if (ordered_presented_tables.index(table.table_name) < border_index)
        puts "Encoding #{table.table_name}..."
        bar = ProgressBar.create(
          total: table.dbf.record_count,
          format: '%a |%B| [%E] (%c/%C) %p%%'
        )
        next if table.dbf.record_count.eql? 0

        table.encode { bar.increment }
        table.copy
      end
    end
  end

  private

  def connect_db
    if ENV['DATABASE_URL'].blank?
      fail 'Specify DATABASE_URL (eg. postgres://localhost/fias)'
    end

    Sequel.connect(ENV['DATABASE_URL'])
  end

  def within_connection(&block)
    db = Sequel.connect(ENV['DATABASE_URL'])
    fias_path = ENV['FIAS_PATH'] || 'tmp/fias'
    only = *ENV['TABLES'].to_s.split(',')
    files = Fias::Import::Dbf.new(fias_path).only(*only)
    prefix = ENV['PREFIX']
    tables = Fias::Import::Tables.new(db, files, *[prefix].compact)

    diff = only - files.keys.map(&:to_s)
    puts "WARNING: Missing DBF files for: #{diff.join(', ')}" if diff.any?

    yield(tables)
  end
end