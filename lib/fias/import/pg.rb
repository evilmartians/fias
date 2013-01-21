module Fias
  module Import
    class PgImporter
      # Класс для импорта данных из ФИАС в PostgreSQL.
      # Используется COPY FROM STDIN.
      def initialize(raw_connection, wrapper, options = {})
        self.prefix         = options.delete(:prefix) || 'fias'
        self.raw_connection = raw_connection
        self.wrapper        = wrapper
      end

      # Генерирует схему базы для ActiveRecord в виде строки
      def schema
        "".tap do |s|
          wrapper.tables.each do |accessor, table|
            s << %{create_table "#{table_name(accessor)}", id: false do |t|\n}
            s << dump_schema_for(accessor, table)
            s << "end\n"

            s << alter_table_to_pg_uuids(accessor)
          end

          s << %{create_table "#{table_name('houses')}", id: false do |t|\n}
          s << dump_schema_for(:houses, wrapper.houses.values.first)
          s << "  t.column :regioncode, :integer\n"
          s << "end\n"
        end
      end

      def import(&block)
        wrapper.tables.each do |accessor, table|
          import_table(accessor, table, &block)
        end
      end

      def import_houses(&block)
        wrapper.houses.each do |region, table|
          import_houses_for_region(region, table, &block)
        end
      end

      private
      def dump_schema_for(accessor, table)
        "".tap do |s|
          table.columns.each do |column|
            column_name = column.name.downcase
            column_def = column.schema_definition
            s << "  t.column #{column_def}"
          end
        end
      end

      def alter_table_to_pg_uuids(accessor)
        "".tap do |s|
          columns = wrapper.class::CONVERT_TO_UUID[accessor]
          if columns.present?
            columns.each do |column|
              s << %{ActiveRecord::Base.connection.execute("ALTER TABLE #{table_name(accessor)} ALTER COLUMN #{column} TYPE UUID USING CAST (#{column} AS UUID);")\n}
            end
          end
        end
      end

      def import_table(accessor, table, &block)
        fields = table_fields(table)
        columns = table_columns(fields)

        tn = table_name(accessor)

        truncate_table(tn)
        copy_from_stdin(tn, columns)

        table.each_with_index do |record|
          data = record.to_a
          put_data(data)
          yield(accessor, data) if block_given?
        end

        put_copy_end
      end

      def import_houses_for_region(region, table, &block)
        fields = table_fields(table)
        fields << :regioncode
        columns = table_columns(fields)

        tn = table_name('houses')

        truncate_table(tn)
        copy_from_stdin(tn, columns)

        table.each_with_index do |record|
          data = record.to_a
          data << region
          put_data(data)
          yield('houses', data) if block_given?
        end

        put_copy_end
      end

      def table_name(table)
        "#{prefix}_#{table}"
      end

      def table_fields(table)
        table.columns.map(&:name).map(&:downcase)
      end

      def table_columns(fields)
        fields.join(',')
      end

      def truncate_table(table_name)
        raw_connection.exec "TRUNCATE TABLE #{table_name};"
      end

      def copy_from_stdin(table_name, columns)
        sql = "COPY #{table_name} (#{columns}) FROM STDIN NULL AS '-nil-'\n"
        raw_connection.exec(sql)
      end

      def put_data(data)
        data.map! { |item| item == "" ? '-nil-' : item }
        line = data.join("\t") + "\n"
        raw_connection.put_copy_data(line)
      end

      def put_copy_end
        raw_connection.put_copy_end

        while res = raw_connection.get_result
          result_status = res.res_status(res.result_status)
          unless result_status == 'PGRES_COMMAND_OK'
            raise "Import failure: #{result_status}"
          end
        end
      end

      attr_accessor :raw_connection, :wrapper
      attr_accessor :prefix, :table_mappings
    end
  end
end