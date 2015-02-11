module Fias
  module Import
    class Dbf
      def initialize(path, encoding = DEFAULT_ENCODING)
        @path = path
        @files = {}

        unless Dir.exist?(@path)
          fail ArgumentError, "FIAS database path #{@path} does not exists"
        end

        open_files(encoding)
      end

      def only(*names)
        return @files if names.empty?

        names = names.map do |name|
          name = name.to_sym
          name == :houses ? HOUSE_TABLES.keys : name
          name == :nordocs ? NORDOC_TABLES.keys : name
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
          @files[accessor] = dbf if dbf
        end
      end

      def self.n_tables(title)
        tables = (1..99).map do |n|
          [
            format('%s%0.2d', title, n).to_sym,
            format('%s%0.2d.dbf', title.upcase, n)
          ]
        end

        tables.flatten!

        Hash[*tables]
      end

      HOUSE_TABLES = n_tables('house')
      NORDOC_TABLES = n_tables('nordoc')

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
      ).merge(
        NORDOC_TABLES
      )

      DEFAULT_ENCODING = Encoding::CP866
    end
  end
end
