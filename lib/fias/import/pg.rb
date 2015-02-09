module Fias
  module Import
    class Pg
      def initialize(connection, table_name, dbf)
        @connection = connection
        @table_name = table_name
        @dbf = dbf
      end

      def import
        encoder = PgDataEncoder::EncodeForCopy.new
        dbf.each do |record|
          encoder.add(record.to_a)
        end
      end
    end
  end
end
