module Fias
  class Query
    VALID_KEYS = %i(street subcity city district region)

    def initialize(query = {})
      @query = query
      @query.assert_valid_keys(*VALID_KEYS)

      extract_statuses
      remove_duplicates
      fix_federal_cities
    end

    attr_reader :query, :sanitized

    VALID_KEYS.each { |key| define_method(key) { @sanitized[key] } }

    private

    def extract_statuses
      extracted = @query.map do |name, value|
        next if value.blank? || !value.is_a?(String)
        [name, Fias::Name::Extract.extract(value)]
      end

      @sanitized = Hash[*extracted.compact.flatten(1)]
    end

    def remove_duplicates
      @sanitized.delete(:region) if region == city
      @sanitized.delete(:district) if [region, city].include?(district)
      @sanitized.delete(:street) if street == district
    end

    def fix_federal_cities
      federal_city = find_federal_city
      return unless federal_city

      @sanitized[:subcity] = city if city && city[0] != federal_city[0]

      if federal_city[1].blank?
        federal_city = Fias::Name::Extract.extract("г #{federal_city.first}")
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
  end
end
