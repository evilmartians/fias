module Fias
  module Importer
    # Класс для импорта данных из ФИАС в PostgreSQL.
    # Используется COPY FROM STDIN.
    class Pg < Base
      def schema_for(name, table_name, dbf)
        super + alter_table_to_pg_uuids(name, table_name)
      end

      private
      def alter_table_to_pg_uuids(name, table_name)
        "".tap do |s|
          columns = CONVERT_TO_UUID[name]
          if columns.present?
            columns.each do |column|
              s << %{ActiveRecord::Base.connection.execute("ALTER TABLE #{table_name} ALTER COLUMN #{column} TYPE UUID USING CAST (#{column} AS UUID);")\n}
            end
          end
        end
      end

      def import_table(name, table_name, dbf, &block)
        fields = table_fields(dbf)
        columns = table_columns(fields)

        truncate_table(table_name)
        copy_from_stdin(table_name, columns)

        dbf.each_with_index do |record, index|
          should_import = yield(name, record.attributes, index) if block_given?

          unless should_import === false
            data = record.to_a
            put_data(data)
          end
        end

        put_copy_end
      end

      def truncate_table(table_name)
        connection.exec "TRUNCATE TABLE #{table_name};"
      end

      def table_fields(table)
        table.columns.map(&:name).map(&:downcase)
      end

      def table_columns(fields)
        fields.join(', ')
      end

      def copy_from_stdin(table_name, columns)
        sql = "COPY #{table_name} (#{columns}) FROM STDIN NULL AS '-nil-'\n"
        connection.exec(sql)
      end

      def put_data(data)
        data.map! { |item| item == "" ? '-nil-' : item }
        line = data.join("\t") + "\n"
        connection.put_copy_data(line)
      end

      def put_copy_end
        connection.put_copy_end

        while res = connection.get_result
          result_status = res.res_status(res.result_status)
          unless result_status == 'PGRES_COMMAND_OK'
            raise "Import failure: #{result_status}"
          end
        end
      end
    end

    # Эти поля нужно отконвертировать в тип UUID после создания
    CONVERT_TO_UUID = {
      address_objects: %w(aoguid aoid previd nextid parentguid)
    }
  end
end