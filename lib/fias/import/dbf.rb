module Fias
  module Import
    class Dbf
      def initialize(path, encoding = DEFAULT_ENCODING)
        unless Dir.exist?(path)
          fail ArgumentError, 'FIAS database path does not exists'
        end

        @path = path
        @files = {}

        open_files(encoding)
      end

      def only(*names)
        names = names.map do |name|
          name = name.to_sym
          name == :houses ? HOUSE_TABLES.keys : name
        end

        names.flatten!

        @files.slice(*names)
      end

      attr_reader :files

      private

      def open_files(encoding)
        TABLES.each do |accessor, dbf_filename|
          filename = File.join(@path, dbf_filename)

          next unless File.exist?(filename)

          dbf = DBF::Table.new(filename, nil, encoding)
          @files[accessor] = dbf
        end
      end

      def self.house_tables
        tables = (1..99).map do |n|
          [format('house%0.2d', n).to_sym, format('HOUSE%0.2d.dbf', n)]
        end

        tables.flatten!

        Hash[*tables]
      end

      HOUSE_TABLES = house_tables

      TABLES = {
        address_object_types: 'SOCRBASE.DBF',
        current_statuses: 'CURENTST.DBF',
        actual_statuses: 'ACTSTAT.DBF',
        operation_statuses: 'OPERSTAT.DBF',
        center_statuses: 'CENTERST.DBF',
        interval_statuses: 'INTVSTAT.DBF',
        estate_statues: 'ESTSTAT.DBF',
        structure_statuses: 'STRSTAT.DBF',
        address_objects: 'ADDROBJ.DBF',
        house_intervals: 'HOUSEINT.DBF',
        landmarks: 'LANDMARK.DBF'
      }.merge(
        HOUSE_TABLES
      )

      DEFAULT_ENCODING = Encoding::CP866
    end
  end
end
