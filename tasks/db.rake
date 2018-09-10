require 'fias'
require 'ruby-progressbar'
require 'sequel'

namespace :fias do
  desc 'Create FIAS tables (PREFIX, FIAS_PATH to dbfs, DATABASE_URL and TABLES)'
  task :create_tables do
    fias_path = ENV['FIAS_PATH'] || 'tmp/fias'
    files = Dir.entries(fias_path).select{|asd| asd =~ /\w+\.\w/}
    within_connection(files) do |tables|
      tables.create
      puts "#{tables.files.keys.join(', ')} created."
    end
  end

  desc 'Import FIAS data (PREFIX, FIAS_PATH to dbfs, DATABASE_URL and TABLES)'
  task :import do
    fias_path = ENV['FIAS_PATH'] || 'tmp/fias'

    files_paths = Dir.glob("#{fias_path}/[^D]*.DBF")
    filenames = files_paths.map{|filepath| File.basename filepath}
    total_files_records = files_paths.map{|file_path| DBF::Table.new(file_path, nil, 'cp866').record_count}.flatten.compact.sum
    files_count = filenames.count

    sorted_filenames = fias_sorter(filenames, [['split', '.'],'first'])
    portion_size = 10 # size depends on RAM
    portions = (sorted_filenames.count/portion_size)+1

    start_time = Time.now
    current_table_counter = 0
    current_record = 0

    portions.times do |portion_count|
      ap '____________________'

      within_connection(sorted_filenames[portion_count*portion_size..portion_count*portion_size+portion_size-1]) do |tables|
        #byebug
        db = Sequel.connect(ENV['DATABASE_URL'])

        tables_array = tables.copy

        ordered_presented_tables =
           tables_array.map(&:table_name).select do |table_name|
             db.table_exists? table_name
           end
        ordered_presented_tables = fias_sorter(ordered_presented_tables)
        border_index = ordered_presented_tables.count-1

        ordered_presented_tables.reverse.each do |table|
          break if db[table].count > 0
          border_index = ordered_presented_tables.index table
        end

        fias_sorter(tables_array, 'table_name').each do |table|

          current_table_counter += 1
          if (ordered_presented_tables.index(table.table_name) < border_index)
            current_record += table.dbf.record_count
            next
          end

          puts "Encoding #{table.table_name}..."
          bar = ProgressBar.create(
             total: table.dbf.record_count,
             format: "%a |%B| [%E] (%c/%C) %p%% Всего записей 0 из #{total_files_records}"
          )
          next if table.dbf.record_count.eql? 0

          table.encode do
            current_record += 1
            passed_time = Time.now - start_time
            time_per_record = passed_time.to_f/current_record
            total_time_forecast = time_per_record*total_files_records
            elapsed_time = total_time_forecast - passed_time

            bar.format = "%a |%B| [%E] (%c/%C) %p%% Файл (#{current_table_counter}/#{files_count}). Запись (текущая/всего) (#{current_record}/#{total_files_records}) #{(current_record*100.0/total_files_records).round(0)}%. Времени (прошло/осталось/всего) (#{sprintf('%.1f',passed_time)}/#{sprintf('%.1f',elapsed_time)}/#{sprintf('%.1f',total_time_forecast)}) Времени на запись #{sprintf('%.5f',time_per_record)}"
            bar.increment
          end
          table.copy
        end

        puts IO.readlines('/proc/loadavg').first.split[0..2].map{|e| e.to_f}
        puts %x(free)
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

  def fias_sorter(tables_array, methods=nil)
    primary_region = '02'
    methods = [methods].flatten(1).compact
    tables_array.sort do |first_table, second_table|

      first = inject_method_chain(first_table, methods).to_s
      second = inject_method_chain(second_table, methods).to_s

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

  def inject_method_chain(value, methods=[])
    methods.inject(value) do |recepient_value, method|
      if method.instance_of?(Array)
        recepient_value.send(method.first, method.second)
      else
        recepient_value.send(method)
      end
    end
  end

  def within_connection(files_list, &block)
    db = Sequel.connect(ENV['DATABASE_URL'])
    fias_path = ENV['FIAS_PATH'] || 'tmp/fias'
    only = *ENV['TABLES'].to_s.split(',')
    files = Fias::Import::Dbf.new(fias_path, files_list).only(*only)
    prefix = ENV['PREFIX']
    tables = Fias::Import::Tables.new(db, files, *[prefix].compact)

    diff = only - files.keys.map(&:to_s)
    puts "WARNING: Missing DBF files for: #{diff.join(', ')}" if diff.any?

    yield(tables)
  end
end
