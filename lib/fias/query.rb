module Fias
  module Query
    def initialize(params)
      @params = Params.new(params)
    end

    attr_reader :params

    def perform
      @variants = find_possible_variants
    end

    protected

    def find(_tokens)
      fail NotImplementedError
#          where.overlap(tokens: search_tokens).
#          visible.
#          pluck(*FIELDS)

    end

    private

    def find_possible_variants
      result = @params.sanitized.map do |key, (name, *_rest)|
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

  end
end
