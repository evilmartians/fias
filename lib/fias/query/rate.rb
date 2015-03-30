module Fias
  module Query
    class Rate
      def rate(parts, possible_chains)
        subject_type, _ = parts.first

        rated_chains = possible_chains.map do |chain|
          rate =
            rate_for_subject(parts, chain) +
            rate_for_found_parts(chain) +
            rate_for_status(parts, chain) +
            rate_for_deepness(chain) +
            rate_for_name_proximity(parts, chain)

          [rate, chain]
        end

        rated_chains = keep_only_valuable_chains(rated_chains)

        rated_chains.map do |rate, chain, rate_parts|
          point = Addressing::Object.find(chain.first.id)
          [rate, point.ancestors.push(point)]
        end
      end

      private
      def rate_for_subject(parts, chain)
        expected_kind, _ = parts.first
        expected_kind == chain.first.kind ? RATES[:subject] : 0
      end

      def rate_for_status(parts, chain)
        chain_by_kind = chain.index_by(&:kind)

        parts.sum do |kind, (_, *expected_status)|
          received_status = chain_by_kind[kind].try(:status)

          status_found =
            expected_status.present? &&
            received_status.in?(expected_status)

          status_found ? RATES[:status] : 0
        end
      end

      def rate_for_found_parts(chain)
        chain.size * RATES[:found_part]
      end

      def rate_for_deepness(chain)
        chain.first.ancestry.size * RATES[:deep]
      end

      def rate_for_name_proximity(parts, chain)
        chain_by_kind = chain.index_by(&:kind)

        parts.sum do |kind, (expected_name, _)|
          received_name   = chain_by_kind[kind].try(:name) || ''
          proximity       = Addressing::Tokenizer.proximity(
            expected_name, received_name
          )

          proximity * RATES[:name]
        end
      end

      def keep_only_valuable_chains(chains)
        chains.sort_by!(&:first).reverse!
        if chains.first.present?
          max_rate = chains.first.first
          chains.keep_if { |c| c.first == max_rate }
        else
          []
        end
      end

      RATES = {
        subject: 10000,   # It's most important to match street if street is requested
        found_part: 1000, # Than, maximum parts number should coincide
        status: 100,      # Than, status should coincide,
        name: 5,          # Than, how close name matches are
        deep: -1          # Than, how deep is matching chain situated
      }
    end
  end
end
