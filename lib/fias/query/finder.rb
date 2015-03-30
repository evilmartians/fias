module Fias
  module Query
    class Finder
      def initialize(params, find)
        @params = params
        @find = find
      end

      def assumption
        find_endpoints
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
          overlaps = parents.keys & endpoint[:ancestry]

          if parents.blank? || overlaps.present?
            [endpoint] + endpoint[:ancestry].map { |id| parents[id] }.compact
          end
        end

        chains.compact
      end

      def endpoints_parents
        @endpoints
          .values
          .slice(1..-1)
          .flatten
          .reverse
          .index_by { |endpoint| endpoint[:id] }
      end
    end
  end
end
