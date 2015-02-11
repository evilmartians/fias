module Fias
  module Import
    class TreeBuilder
      def initialize(db, options = {})
        @db = db
        @options = options
        @table = options.fetch(:table).to_sym
        @key = options.fetch(:key)
        @parent_key = options.fetch(:parent_key)
        @id = options.fetch(:id, :id)
        @where = options.fetch(:where, {})
        @parent_id = options.fetch(:parent_id, :parent_id)
      end

      def build_parent_id_by_key
        @parent_id_by_key ||= parent_id_by_key
      end

      private

      def data
        @data ||=
          @db[@table].where(@where).select_map([@id, @key, @parent_key])
      end

      def data_by_key
        @data_by_key ||= data.index_by { |r| r[1] }
      end

      def id_parent_id
        data.map do |row|
          id, _, key = row

          if key
            parent_id = data_by_key[key]
            parent_id = parent_id[0] if parent_id
          end

          [id, parent_id]
        end
      end

      def parent_id_by_key
        {}.tap do |rows|
          id_parent_id.each do |(id, parent_id)|
            rows[parent_id] ||= []
            rows[parent_id] << id
          end
        end
      end
    end
  end
end
