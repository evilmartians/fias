module Fias
  module Query
    class Finder
      def initialize(params, find)
        @params = params
        @find = find
      end

      def assumption
        find_candidates
        #build_chains
      end

      private

      def find_candidates
        @candidates = @params.map { |key, (name, *)| find_candidate(key, name) }
        @candidates = Hash[candidates]
      end

      def find_candidate(key, name)
        words = Fias::Name::Split.split(name)
        candidates = find(words)
        candidates = reject_candidates(candidates, name)
        [key, candidates]
      end

      def find(words)
        @find.call(words)
      end

      def reject_candidates(candidates, name)
        forms = Fias::Name::Synonyms.forms(name)

        candidates.reject do |candidate|
          candidate_forms = Fias::Name::Synonyms.forms(candidate[:name])
          (forms & candidate_forms).blank?
        end
      end

      def build_chains(variants)
        beginning = variants.values.first
        parents_by_id = variants.values.slice(1..-1).flatten.reverse.index_by(&:id)

        chains = beginning.map do |variant|
          parent_ids_overlap = parents_by_id.keys & variant.ancestry

          if parents_by_id.blank? || parent_ids_overlap.present?
            [variant] + variant.ancestry.map { |id| parents_by_id[id] }.compact
          end
        end

        chains.compact
      end
=begin
      def build_result_for(kind, variant)
        id, name, status, ancestry, tokens = variant
        ancestry = split_ancestry(ancestry)

        Result.new(id, name, status, ancestry, tokens, kind)
      end

      def split_ancestry(ancestry)
        ancestry.to_s.split('/').map(&:to_i).reverse
      end
=end
#      FIELDS = %i(id name status ancestry tokens)
#      Result = Struct.new(*FIELDS + [:kind])
    end
  end
end
