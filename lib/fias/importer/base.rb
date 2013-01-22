module Fias
  module Importer
    class Base
      def initialize(connection, options = {})
        self.prefix         = options.delete(:prefix) || 'fias'
        self.connection     = connection
      end

      # На входе - хеш (имя таблицы => dbf)
      def schema(tables)
        "".tap do |s|
          tables.each do |name, dbf|
            if dbf.present?
              s << schema_for(name, table_name(name), dbf)
            end
          end
        end
      end

      def schema_for(name, table_name, dbf)
        "".tap do |s|
          s << %{create_table "#{table_name}", id: false do |t|\n}
          s << schema_columns(name, dbf)
          s << "end\n"
        end
      end

      def import(tables, &block)
        tables.each do |name, dbf|
          if dbf
            import_table(name, table_name(name), dbf, &block)
          end
        end
      end

      def import_table(name, table_name, dbf, &block)
        raise NotImplementedError, 'Implement this in concrete class'
      end

      protected
      attr_accessor :prefix, :connection

      private
      def table_name(name)
        "#{prefix}_#{name}"
      end

      def schema_columns(accessor, table)
        "".tap do |s|
          table.columns.each do |column|
            column_name = column.name.downcase
            column_def  = column.schema_definition
            s << "  t.column #{column_def}"
          end
        end
      end
    end
  end
end