module Fias
  module Name
    module Extract
      class << self
        def extract(name)
          return if name.blank?
          name = cleanup(name)

          matches = find(name)
          rates = assign_rates(name, matches)
          winner = pick_winner(rates)
          return [name] unless winner

          extract_name(name, winner)
        end

        private

        def cleanup(name)
          name.split(' ').join(' ').strip
        end

        def find(name)
          matches = Fias.config.index.keys.map do |query|
            match = name.match(/(\s|^)(#{Regexp.escape(query)})(\.|\s|$)/ui)
            match if match && match[2]
          end
          matches.compact
        end

        def assign_rates(name, matches)
          matches.map { |match| rate_match(name, match) }
        end

        def rate_match(name, match)
          short_name = match[2]

          rate =
            (ends_with_dot?(short_name) * REWARD[:dot]) +
            (starts_with_small_letter?(short_name) * REWARD[:small_letter]) +
            (border_proximity(name, match))

          rate *= 100
          rate += short_name.size

          [rate, match]
        end

        def border_proximity(name, match)
          head = name.size - match.begin(1) + REWARD[:head]
          tail = match.end(2)
          [head, tail].max
        end

        def ends_with_dot?(value)
          value[-1] == '.' ? 1 : 0
        end

        def starts_with_small_letter?(value)
          value[0] =~ SMALL_LETTER ? 1 : 0
        end

        def pick_winner(rates)
          rates = rates.sort_by(&:first).reverse
          rate, match = rates.first
          return if (rates[1..-1] || []).any? { |(r, _)| rate == r }
          match
        end

        def extract_name(name, winner)
          short_name = winner[2]
          toponym = cleanup(name.gsub(winner.regexp, ' '))
          return [name] if toponym.strip.blank?
          [cleanup(toponym), Canonical.canonical(short_name)].flatten
        end

        SMALL_LETTER = /[а-яё]/u

        REWARD = {
          dot: 3, small_letter: 2, head: 1
        }
      end
    end
  end
end
