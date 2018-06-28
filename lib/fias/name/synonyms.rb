module Fias
  module Name
    module Synonyms
      class << self
        def expand(name)
          Split
              .split(name)
              .map { |token| Array.wrap(tokenize(name, token)) }
        end

        def tokens(name)
          expand(name).flatten.uniq
        end

        def forms(name)
          recombine(expand(name))
        end

        private

          def tokenize(name, token)
            synonyms(token)          ||
                bracketed(name, token) ||
                proper_names(token)    ||
                initials(token)        ||
                annivesary(token)      ||
                numerals(token)        ||
                token
          end

          def synonyms(token)
            Fias.config.synonyms_index[token]
          end

          def bracketed(name, token)
            match = name.match(IN_BRACKETS)
            [token, OPTIONAL] if match && match[1].include?(token)
          end

          def proper_names(token)
            [token, OPTIONAL] if Fias.config.proper_names.include?(token)
          end

          def initials(token)
            return unless
                (Fias::INITIALS =~ token) && (Fias::SINGLE_INITIAL =~ token)

            [token, OPTIONAL]
          end

          def annivesary(token)
            return unless token =~ Fias::ANNIVESARIES

            ANNIVESARY_FORMS.map do |form|
              token.gsub(Fias::ANNIVESARIES, form)
            end
          end

          def numerals(token)
            return unless (/^\d+/ =~ token) || (Fias::ANNIVESARIES =~ token)
            numerals_for(token)
          end

          def numerals_for(numeral)
            n = numeral.gsub(/[^\d]/, '')

            suffixes =
                NUMERAL_SUFFIXES.map do |suffix|
                  ["#{n}#{suffix}", "#{n}-#{suffix}"]
                end

            suffixes.flatten + [n]
          end

          def recombine(variants)
            return variants if variants.empty?
            head, *rest = variants

            forms = head.product(*rest)
            forms
                .map { |variant| variant.reject(&:blank?).sort.join(' ') }
                .flatten
          end

          IN_BRACKETS      = /\((.*)\)/
          OPTIONAL         = ''
          NUMERAL_SUFFIXES = %w(й я е ая ий ый ой ые ое го)
          ANNIVESARY_FORMS =
              ['\1-летия', '\1-лет', '\1 летия', '\1 лет', '\1-летие', '\1 летие']
      end
    end
  end
end
