module Fias
  module Query
    class Finder
      def initialize(params, find)
        @params = params
        @find = find
      end

      def assumption
        find_endpoints
        return [] if @endpoints.blank?
        reject_inconsistent_chains
      end

      private

      def find_endpoints
        @endpoints = @params.split.keys.map do |key|
          find_endpoint(key)
        end
        @endpoints = Hash[@endpoints]
        inject_key_to_endpoints
      end

      def find_endpoint(key)
        words = @params.split[key]
        endpoints = find(words)
        endpoints = reject_endpoints(endpoints, key)
        [key, endpoints]
      end

      def find(words)
        @find.call(words)
      end

      def reject_endpoints(endpoints, key)
        forms = @params.forms[key]

        endpoints.reject do |endpoint|
          (forms & endpoint[:forms]).blank?
        end
      end

      def inject_key_to_endpoints
        @endpoints.each do |key, endpoints|
          endpoints.each { |endpoint| endpoint[:key] = key }
        end
      end

      def reject_inconsistent_chains
        starting_endpoints = @endpoints.values.first
        parents = endpoints_parents

        chains = starting_endpoints.map do |endpoint|
          overlaps = parents.keys & parentage(endpoint)

          if parents.blank? || overlaps.present?
            [endpoint] + parentage(endpoint).map { |id| parents[id] }.compact
          end
        end

        chains.compact
      end

      def endpoints_parents
        parents = @endpoints.values.slice(1..-1)
        return [] if parents.nil?
        parents
          .flatten
          .reverse
          .index_by { |endpoint| endpoint[:id] }
      end

      def parentage(endpoint)
        endpoint[Fias.setting(:parentage_column).to_sym].tap do |parentage|
          warn(<<-DEPRECATE) unless parentage.is_a? Array
            Now `ancestry` column was renamed to `parentage` for possibility of using Ancestry gem.
            Please, add setting `parentage_column` in your app, if you want to continue use `ancestry` column.
            ```
              Fias.config.add_setting(:parentage_column, :ancestry)
            ```
          DEPRECATE
        end
      end
    end
  end
end
