module Fias
  module Import
    class Copy
      def initialize(table_name, dbf)
        @connection = ActiveRecord::Base.connection
        @table_name = table_name
        @dbf = dbf
        @encoder = PgDataEncoder::EncodeForCopy.new
      end

      def encode
        @dbf.each do |record|
          @encoder.add(record.to_a)
          yield if block_given?
        end
      end

      def perform
        prepare
        start
        copy
        finish
      end

      private

      def columns
        @dbf.columns.map(&:name).map(&:downcase).map { |c| %("#{c}") }.join(',')
      end

      def prepare
        @connection.execute(
          "TRUNCATE TABLE #{@table_name}; SET client_min_messages TO warning;"
        )
      end

      def start
        raw_connection.exec(
          "COPY #{@table_name} (#{columns}) FROM STDIN BINARY\n"
        )
      end

      def copy
        io = @encoder.get_io

        while (line = io.readpartial(BLOCK_SIZE))
          raw_connection.put_copy_data(line)
        end
      rescue EOFError => _e
        return
      end

      def finish
        raw_connection.put_copy_end

        while (res = raw_connection.get_result)
          result_status = res.res_status(res.result_status)
          unless result_status == 'PGRES_COMMAND_OK'
            fail "Import failure: #{result_status}"
          end
        end
      end

      def raw_connection
        @raw_connection ||= @connection.pool.checkout.raw_connection
      end

      BLOCK_SIZE = 10_240
    end
  end
end
