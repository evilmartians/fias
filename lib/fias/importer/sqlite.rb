module Fias
  module Importer
    # Нужно для :memory: баз в первую очередь
    class Sqlite < Base
      def import_table(name, table_name, dbf, &block)
        truncate_table(table_name)

        qmarks = ['?'] * dbf.columns.keys.size
        qmarks = qmarks.join(', ')

        dbf.each_with_index do |record, index|
          data = record.attributes

          should_import = yield(name, data, index) if block_given?

          unless should_import === false
            columns = data.keys.join(', ')

            values = data.values.map do |value|
              if value.is_a?(Date)
                value.to_s
              else
                value
              end
            end

            connection.execute("INSERT INTO #{table_name} (#{columns}) VALUES (#{qmarks});", values)
          end
        end
      end

      private
      def truncate_table(table_name)
        connection.execute "DELETE FROM #{table_name} WHERE 1"
      end
    end
  end
end