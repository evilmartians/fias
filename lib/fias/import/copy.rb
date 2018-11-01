module Fias
  module Import
    class Copy
      attr_reader :dbf, :table_name

      def initialize(db, table_name, dbf, types = {})
        @db = db
        @table_name = table_name.to_sym
        @dbf = dbf
        @encoder = PgDataEncoder::EncodeForCopy.new(
            column_types: map_types(types)
        )
      end

      def encode
        @dbf.each do |record|
          line = record.to_a.map { |v| v == '' ? nil : v }
          @encoder.add(line)
          yield if block_given?
        end
      end

      def copy
        prepare
        copy_into
      end

      private

        def map_types(types)
          types = types.map do |name, type|
            index = columns.index(name.to_sym)
            [index, type] if index
          end
          Hash[*types.compact.flatten]
        end

        def columns
          @columns ||= @dbf.columns.map(&:name).map(&:downcase).map(&:to_sym)
        end

        def prepare
          @db[@table_name].truncate
          @db.run('SET client_min_messages TO warning;')
        end

        def copy_into
          io = @encoder.get_io

          @db.copy_into(@table_name.to_sym, columns: columns, format: :binary) do
            begin
              io.readpartial(BLOCK_SIZE)
            rescue EOFError => _e
              nil
            end
          end
        end

        BLOCK_SIZE = 65_536 # 10_240
    end
  end
end
