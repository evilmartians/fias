module Fias
  module Name
    module Split
      class << self
        def split(name)
          sanitize(name)
            .gsub(QUOTAS, '')
            .scan(Fias.word)
            .map { |word, _| word.gsub(BRACKETS, '') }
            .map { |word, _| split_initials(word) || word }
            .compact
            .flatten
            .map { |word, _| split_dotwords(word) || word }
            .compact
            .reject(&:blank?)
            .flatten
            .uniq
        end

        private

        def sanitize(name)
          Unicode.downcase(name).gsub('ё', 'е')
        end

        def split_initials(word)
          m_matches = word.match(INITIALS)
          s_matches = word.match(SINGLE_INITIAL)

          if m_matches
            m_matches.values_at(1, 3)
          elsif s_matches
            s_matches.values_at(2, 3)
          end
        end

        def split_dotwords(word)
          return unless word =~ DOTWORD
          dotwords = word.gsub(DOTWORD, '\1 ')
          dotwords.split(' ').uniq.delete_if(&:blank?)
        end
      end

      INITIAL           = /#{Fias::LETTERS}{1,2}\./ui
      INITIALS          = /(#{INITIAL}#{INITIAL}(#{INITIAL})?)(.+|$)/ui
      SINGLE_INITIAL    = /(\.|\s|^)(#{Fias::LETTERS}{1,3}\.)(.+|$)/ui
      DOTWORD           = /(#{LETTERS}{2,}\.)/ui
      BRACKETS          = /(\(|\))/
      QUOTAS            = /[\"\']/
    end
  end
end
