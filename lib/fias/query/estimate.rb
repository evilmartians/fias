module Fias
  module Query
    class Estimate
      def initialize(params, chain)
        @params = params
        @chain = chain
      end

      def estimate
        for_subject +
          for_found_parts +
          for_type +
          for_deepness +
          for_name_proximity
      end

      private

      def for_subject
        expected_type = @params.sanitized.keys.first
        expected_type == @chain.first[:key] ? RATES[:subject] : 0
      end

      def for_found_parts
        @chain.size * RATES[:found_part]
      end

      def for_type
        @params.sanitized.sum do |key, (_, *expected_status)|
          received_status = chain_by_key[key].try(:[], :abbr)

          status_found =
            expected_status.present? &&
            expected_status.include?(received_status)

          status_found ? RATES[:type] : 0
        end
      end

      def for_deepness
        @chain.first[:ancestry].size * RATES[:deep]
      end

      def for_name_proximity
        @params.synonyms.sum do |key, (expected, _)|
          given = chain_by_key[key].try(:[], :tokens) || []
          expected = expected.flatten.uniq

          proximity = (given & expected).size
          proximity * RATES[:name]
        end
      end

      def chain_by_key
        @chain_by_key ||= @chain.index_by { |item| item[:key] }
      end

      RATES = {
        subject: 10000,   # It's most important to match street if street is requested
        found_part: 1000, # Than, maximum parts number should coincide
        type: 100,        # Than, status should coincide,
        name: 5,          # Than, how close name matches are
        deep: -1          # Than, how deep is matching chain situated
      }
    end
  end
end
