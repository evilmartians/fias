module Fias
  module Import
    class Tables
      def initialize(db, files, prefix = DEFAULT_PREFIX)
        @db = db
        @files = files
        @prefix = prefix
      end

      attr_reader :files

      def create
        @files.each do |name, dbf|
          next if dbf.blank?
          create_table(name, dbf)
        end
      end

      def copy
        @files.map do |name, dbf|
          Copy.new(@db, table_name(name), dbf, uuid_column_types(name))
        end
      end

      private

      def table_name(name)
        [@prefix, name].delete_if(&:blank?).join('_').to_sym
      end

      def create_table(name, dbf)
        columns = columns_for(name, dbf)
        @db.create_table(table_name(name)) do
          primary_key :id
          columns.each { |args| column(*args) }
        end
      end

      def columns_for(name, dbf)
        dbf.columns.map do |column|
          column_for(name, column)
        end
      end

      def column_for(name, column)
        alter = UUID[name.to_s[/^\D+/].to_sym]
        column_name = column.name.downcase

        parse_c_def(column.schema_definition).tap do |c_def|
          c_def[1] = :uuid if alter && alter.include?(column_name)
          c_def[1] = :text if c_def[1] == :string
        end
      end

      def parse_c_def(c_def)
        c_def = c_def.strip.split(',').map(&:strip)
        name = c_def[0][1..-2]
        type = c_def[1][1..-1]
        [name, type].map(&:to_sym)
      end

      def uuid_column_types(name)
        uuid = UUID[name.to_s[/^\D+/].to_sym] || []
        Hash[*uuid.zip([:uuid] * uuid.size).flatten]
      end

      UUID = {
         addrob: %w(aoguid aoid previd nextid parentguid normdoc),
         house: %w(aoguid houseguid houseid normdoc),
         stead: %w(steadguid parentguid steadid nextid previd normdoc),
         room: %w(roomid roomguid houseguid nextid previd normdoc),
         nordoc: %w(normdocid)
      }

      DEFAULT_PREFIX = 'fias'
    end
  end
end
