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
      tables_array = tables.copy
      ordered_presented_tables =
         tables_array.map(&:table_name).select do |table_name|
           db.table_exists? table_name
         end
      ordered_presented_tables = fias_sorter(ordered_presented_tables)

      border_index = 0

      ordered_presented_tables.reverse.each do |table|
        break if db[table].count > 0
        border_index = ordered_presented_tables.index table
      end
      total_records = tables_array.map{|table| table.dbf.record_count}.flatten.compact.sum
      files_count = tables_array.count
      start_time = Time.now
      record_counter = 0
      fias_sorter(tables_array, 'table_name').each do |table|
        if (ordered_presented_tables.index(table.table_name) < border_index)
          record_counter += table.dbf.record_count
          next
        end
        puts "Encoding #{table.table_name}..."
        bar = ProgressBar.create(
           total: table.dbf.record_count,
           format: "%a |%B| [%E] (%c/%C) %p%% Всего записей 0 из #{total_records}"
        )
        next if table.dbf.record_count.eql? 0

        table.encode do
           record_counter += 1
           passed_time = Time.now - start_time
           time_per_record = passed_time.to_f/record_counter
           total_time_forecast = time_per_record*total_records
           elapsed_time = total_time_forecast - passed_time
           bar.format = "%a |%B| [%E] (%c/%C) %p%% Файл (#{table_counter}/#{files_count}). Всего записей (#{record_counter}/#{total_records}) #{(record_counter*100.0/total_records).round(0)}%. Времени прошло/осталось/всего (#{sprintf('%.1f',passed_time)}/#{sprintf('%.1f',elapsed_time)}/#{sprintf('%.1f',total_time_forecast)}) Времени на запись #{sprintf('%.5f',time_per_record)}"
           bar.increment
        end
        table.copy
      end
      puts IO.readlines('/proc/loadavg').first.split[0..2].map{|e| e.to_f}
      puts %x(free)
    end
  end

  private

  def connect_db
    if ENV['DATABASE_URL'].blank?
      fail 'Specify DATABASE_URL (eg. postgres://localhost/fias)'
    end

    Sequel.connect(ENV['DATABASE_URL'])
  end

  def fias_sorter(tables_array, methods=nil)
    primary_region = '02'
    methods = [methods].flatten.compact
    tables_array.sort do |first_table, second_table|
      first = methods.inject(first_table){|first_value, method| first_value.send(method)}.to_s
      second = methods.inject(second_table){|first_value, method| first_value.send(method)}.to_s
      if first[/#{primary_region}$/]
        if second[/#{primary_region}$/]
          first <=> second
        else
          -1
        end
      else
        if second[/#{primary_region}$/] || (first[/\d\d$/] && second[/\D\D$/])
          1
        elsif first[/\D\D$/] && second[/\d\d$/]
          -1
        else
          first <=> second
        end
      end
    end
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
