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
            s << schema_for(name, dbf)
          end
        end
      end

      def tables
        @files.map do |name, dbf|
          uuid = UUID[name] || []
          Copy.new(table_name(name), dbf, uuid.zip([:uuid] * uuid.size))
        end
      end

      private

      def schema_for(name, dbf)
        ''.tap do |s|
          s << %(create_table "#{table_name(name)}" do |t|\n)
          s << schema_columns(name, dbf)
          s << "end\n"
        end
      end

      def table_name(name)
        "#{@prefix}_#{name}"
      end

      def schema_columns(name, table)
        ''.tap do |s|
          table.columns.each do |column|
            s << "  t.column #{schema_column_for(name, column)}"
          end
        end
      end

      def schema_column_for(name, column)
        alter = UUID[name]
        column_name = column.name.downcase

        if alter && alter.include?(column_name)
          %("#{column_name}", :uuid\n)
        else
          column.schema_definition
        end
      end

      UUID = {
        address_objects: %w(aoguid aoid previd nextid parentguid)
      }

      DEFAULT_PREFIX = 'fias'
    end
  end
end
