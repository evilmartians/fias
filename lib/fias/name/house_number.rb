module Fias
  module Name
    module HouseNumber
      class << self
        def extract(name)
          return [name, nil] unless contains_number?(name)

          name, number =
            try_split_by_colon(name)   ||
            try_housing(name)          ||
            try_house_word(name)       ||
            try_ends_with_number(name)

          [name.strip, number.strip]
        end

        private

        def contains_number?(name)
          !(name =~ JUST_A_NUMBER) && !(name =~ LINE_OR_MICRODISTRICT) &&
            (
              name =~ COLON ||
              name =~ ENDS_WITH_NUMBER ||
              name =~ HOUSE_WORD ||
              name =~ NUMBER_WITH_HOUSING
            )
        end

        def try_split_by_colon(name)
          name.split(/\s*,\s*/, 2) if name =~ COLON
        end

        def try_housing(name)
          match = name.match(NUMBER_WITH_HOUSING)
          [match.pre_match, "#{match} #{match.post_match}"] if match
        end

        def try_house_word(name)
          match = name.match(HOUSE_WORD)
          [match.pre_match, match.post_match] if match
        end

        def try_ends_with_number(name)
          match = name.match(ENDS_WITH_NUMBER)
          [match.pre_match, match[1]] if match
        end

        def or_words(words)
          words
            .sort_by(&:length)
            .reverse
            .map { |w| Regexp.escape(w) }
            .join('|')
        end
      end

      COLON                 = /\,/
      JUST_A_NUMBER         = /^[\s\d]+$/
      STOPWORDS             = /(микрорайон|линия|микр|мкрн|мкр|лин)/ui
      LINE_OR_MICRODISTRICT = /#{STOPWORDS}\.?[\s\w+]?\d+$/ui
      NUMBER                = /\d+\/?#{Fias::LETTERS}?\d*/ui
      ENDS_WITH_NUMBER      = /(#{NUMBER})$/ui
      HOUSE_WORDS           = %w(ом д дом вл кв)
      HOUSE_WORD =
        /(\s|\,|\.|^)(#{or_words(HOUSE_WORDS)})(\s|\,|\.|$)/ui
      HOUSING_WORDS         = %w(корпус корп к)
      NUMBER_WITH_HOUSING   =
        /#{NUMBER}[\s\,\.]+(#{or_words(HOUSING_WORDS)})[\s\,\.]+#{NUMBER}/ui
    end
  end
end
