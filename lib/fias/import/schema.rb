module Fias
  module Import
    class Schema
      def initialize(files, prefix = DEFAULT_PREFIX)
        @files = files
        @prefix = prefix
      end

      def schema
        ''.tap do |s|
          @files.each do |name, dbf|
            next if dbf.blank?
            s << schema_for(table_name(name), dbf)
          end
        end
      end

      def schema_for(table_name, dbf)
        ''.tap do |s|
          s << %(create_table "#{table_name}" do |t|\n)
          s << schema_columns(dbf)
          s << "end\n"
        end
      end

      private

      def table_name(name)
        "#{@prefix}_#{name}"
      end

      def schema_columns(table)
        ''.tap do |s|
          table.columns.each do |column|
            s << "  t.column #{column.schema_definition}"
          end
        end
      end

      DEFAULT_PREFIX = 'fias'
    end
  end
end
