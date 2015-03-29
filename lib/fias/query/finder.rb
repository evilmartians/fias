module Fias
  module Query
    class Finder
      def initialize(params, finder)
        @params = params
        @finder = finder
      end

      def assumption
        find_possible_variants
        reject_mismatched_names!
        build_chains
      end

      def find_possible_variants
        result = @params.map do |key, (name, *_rest)|
          tokens = Fias::Name::Split.split(name)
          variants = find(tokens)
          reject_mismatched_names!(variants, name)
          variants.map! do |variant|
            build_result_for(key, variant)
          end
          [key, variants]
        end
        Hash[result]
      end

      def reject_mismatched_names!(variants, name)
        search_name_forms = Addressing::Tokenizer.name_forms(name)

        variants.reject! do |variant|
          variant_forms = Addressing::Tokenizer.name_forms(variant.second)
          (search_name_forms & variant_forms).blank?
        end
      end

      def build_possible_chains(variants)
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

      def build_result_for(kind, variant)
        id, name, status, ancestry, tokens = variant
        ancestry = split_ancestry(ancestry)

        Result.new(id, name, status, ancestry, tokens, kind)
      end

      def split_ancestry(ancestry)
        ancestry.to_s.split('/').map(&:to_i).reverse
      end

      def find(tokens)
        @finder.call(tokens)
      end

      FIELDS = %i(id name status ancestry tokens)
      Result = Struct.new(*FIELDS + [:kind])
    end
  end
end
