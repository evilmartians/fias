module Fias
  module Import
    class RestoreParentId
      def initialize(scope, options = {})
        @scope = scope
        @key = options.fetch(:key, :aoguid)
        @parent_key = options.fetch(:parent_key, :parentguid)
        @nextid_key = options.fetch(:nextid_key, :nextid)
        @id = options.fetch(:id, :id)
        @parent_id = options.fetch(:parent_id, :parent_id)
      end

      def restore
        id_grouped_by_parent_id.each do |parent_id, ids|
          @scope.where(id: ids).update(parent_id: parent_id)
        end
      end

      private

      def records
        @records ||= @scope.select_map([@id, @key, @parent_key, @nextid_key])
      end

      def records_by_key
        @records_by_key ||= {}.tap do |rbk|
          records.each { |r| rbk[r[1]] = r if r[3].blank? }
        end
      end

      def id_parent_id_tuples
        records.map do |row|
          id, _, key = row

          if key
            parent_id = records_by_key[key]
            parent_id = parent_id[0] if parent_id
          end

          [id, parent_id]
        end
      end

      def id_grouped_by_parent_id
        {}.tap do |rows|
          id_parent_id_tuples.each do |(id, parent_id)|
            rows[parent_id] ||= []
            rows[parent_id] << id
          end
        end
      end
    end
  end
end
