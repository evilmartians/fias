module Fias
  module Importer
    # Нужно для :memory: баз в первую очередь
    class Sqlite < Base
      def import_table(name, table_name, dbf, &block)
        truncate_table(table_name)

        dbf.each_with_index do |record, index|
          data = record.attributes
          columns = data.keys.join(', ')
          qmarks = ['?'] * data.keys.size
          qmarks = qmarks.join(', ')

          values = data.values.map do |value|
            if value.is_a?(Date)
              value.to_s
            else
              value
            end
          end

          connection.execute("INSERT INTO #{table_name} (#{columns}) VALUES (#{qmarks});", values)

          yield(name, data, index) if block_given?
        end
      end

      private
      def truncate_table(table_name)
        connection.execute "DELETE FROM #{table_name} WHERE 1"
      end
    end
  end
end