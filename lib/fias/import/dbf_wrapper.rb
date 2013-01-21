module Fias
  module Import
    class DbfWrapper
      def initialize(pathspec)
        unless Dir.exists?(pathspec)
          raise ArgumentError, 'FIAS database path does not exists'
        end
        self.pathspec = pathspec

        TABLES.each do |key, dbf_name|
          filename = File.join(pathspec, dbf_name)
          dbf = DBF::Table.new(filename, nil, DEFAULT_ENCODING)

          send("#{key}=", dbf)
        end

        self.houses = {}
        Dir[File.join(pathspec, HOUSE_DBF_MASK)].each do |filename|
          File.basename(filename) =~ /(\d+)/
          region_code = $1.to_i

          dbf = DBF::Table.new(filename, nil, DEFAULT_ENCODING)
          self.houses[region_code] = dbf
        end
      end

      def tables
        hash = TABLES.keys.map do |accessor|
          [accessor, send(accessor)]
        end
      end

      def build_importer(options)
        config = ActiveRecord::Base.connection_config
        if config[:adapter] == 'postgresql'
          import = Fias::Import::PgImporter.new(
            ActiveRecord::Base.connection.raw_connection,
            self,
            options
          )
        else
          raise 'Only postgres supported now, fork'
        end
      end

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
      }
      HOUSE_DBF_MASK = 'HOUSE??.DBF'

      CONVERT_TO_UUID = {
        address_objects: %w(aoguid aoid previd nextid parentguid)
      }

      DEFAULT_ENCODING = Encoding::CP866

      attr_reader   *TABLES.keys
      attr_reader   :houses

      private
      attr_accessor :pathspec
      attr_writer   *TABLES.keys
      attr_writer   :houses
    end
  end
end