module Fias
  module Import
    class TreeBuilder
      def initialize(db, options = {})
        @db = db
        @options = options
        @table = options.fetch(:table).to_sym
        @where = options.fetch(:where, {})
        @key = options.fetch(:key)
        @parent_key = options.fetch(:parent_key)
        @id = options.fetch(:id, :id)
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
        rows = id_parent_id.group_by { |row| row[1] }
        rows.map! { |parent_id, tuples| [parent_id, tuples.map(&:first)] }
        Hash[*rows.flatten]
      end
    end
  end
end
