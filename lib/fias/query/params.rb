module Fias
  module Query
    class Params
      KEYS = %i(street subcity city district region)

      def initialize(params)
        @params = params
        @params.assert_valid_keys(*KEYS)

        extract_names
        remove_duplicates
        move_federal_city_to_correct_place
        strip_house_number
        sort
        extract_synonyms
        split_sanitized
      end

      attr_reader :params, :sanitized, :synonyms, :split

      KEYS.each { |key| define_method(key) { @sanitized[key] } }

      private

      def extract_names
        extracted = @params.map do |name, value|
          if value.is_a?(Array)
            [name, value]
          else
            next if value.blank? || !value.is_a?(String)
            [name, Fias::Name::Extract.extract(value)]
          end
        end

        @sanitized = Hash[*extracted.compact.flatten(1)]
      end

      def remove_duplicates
        @sanitized.delete(:region) if region == city
        @sanitized.delete(:district) if [region, city].include?(district)
        @sanitized.delete(:street) if street == district
      end

      def move_federal_city_to_correct_place
        federal_city = find_federal_city
        return unless federal_city

        @sanitized[:subcity] = city if city && city[0] != federal_city[0]

        if federal_city[1].blank?
          federal_city += Fias::Name::Canonical.canonical('г.')
        end

        @sanitized[:city] = federal_city
        @sanitized.delete(:district)
        @sanitized.delete(:region)
      end

      def find_federal_city
        @sanitized.values.find do |value|
          value.is_a?(Array) && Fias::FEDERAL_CITIES.include?(value.first)
        end
      end

      def strip_house_number
        return if street.blank?
        @sanitized[:street] = Fias::Name::HouseNumber.extract(street).first
      end

      def sort
        sanitized = KEYS.map do |key|
          value = @sanitized[key]
          [key, value] if value.present?
        end
        @sanitized = Hash[sanitized.compact]
      end

      def extract_synonyms
        @synonyms = @sanitized.map do |key, value|
          [key, Fias::Name::Synonyms.expand(value.first)]
        end
        @synonyms = Hash[@synonyms]
      end

      def split_sanitized
        @split = @sanitized.map do |key, value|
          [key, Fias::Name::Split.split(value.first)]
        end
        @split = Hash[@split]
      end
    end
  end
end
