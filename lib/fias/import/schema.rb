module Fias
  module Import
    class Schema
      def initialize(files, prefix = Fias::Import::DEFAULT_PREFIX)
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
        if alter && alter.include?(column.name)
          %("#{column.name.downcase}", :uuid\n)
        else
          column.schema_definition
        end
      end

      UUID = {
        address_objects: %w(AOGUID AOID PREVID NEXTID PARENTGUID)
      }
    end
  end
end
