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
            s << schema_for(table_name(name), dbf)
          end
        end
      end

      def pg
        alter = @files.map do |name, _|
          columns = PG_UUID[name]
          next if columns.blank?
          pg_alter(name, columns)
        end

        alter.compact.flatten.join
      end

      private

      def schema_for(table_name, dbf)
        ''.tap do |s|
          s << %(create_table "#{table_name}" do |t|\n)
          s << schema_columns(dbf)
          s << "end\n"
        end
      end

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

      def pg_alter(name, columns)
        table_name = table_name(name)

        columns.map do |column|
          %(
            ActiveRecord::Base.connection.execute(
              "ALTER TABLE #{table_name}
                ALTER COLUMN #{column}
                TYPE UUID USING CAST (#{column} AS UUID);")\n
          )
        end
      end

      PG_UUID = {
        address_objects: %w(aoguid aoid previd nextid parentguid)
      }
    end
  end
end
