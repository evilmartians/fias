module Fias
  module Import
    class Copy
      def initialize(connection, table_name, dbf)
        @connection = connection
        @table_name = table_name
        @dbf = dbf
      end

      def start
        encoder = PgDataEncoder::EncodeForCopy.new
        @dbf.each do |record|
          encoder.add(record.to_a)
        end
      end

      private

      def columns
        @dbf.columns.map(&:name).map(&:downcase)
      end
    end
  end
end
