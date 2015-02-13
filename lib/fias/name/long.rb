# 1) УБрать все точки перед пробелом или концом строки.
# 2) Убрать trailing whitespace

module Fias
  module Name
    module Long
      class << self
        # Splits city status and name: "г Краснодар => [Краснодар, г, Город]"
        def extract(full_name)
          full_name = cleanup(full_name)

        end

        def cleanup(full_name)
          full_name.split(' ').join(' ').strip
        end

        def old_extract(full_name)
          full_name = strip_trailing(full_name.to_s.strip)
          return nil if full_name.blank?

          replace_exceptions!(full_name)

          results = find_status(full_name)
          result  = get_matching_result(results)

          if result.present?
            result.slice(1..-1)
          else
            [strip_trailing(full_name)]
          end
        end

        def full_for(status)
          full_status, _ = abbrs.find do |full, abbrs|
            abbrs = downcased_abbrs(abbrs)
            abbrs.include?(status.mb_chars.downcase.to_s)
          end
          full_status
        end

        def options
          abbrs.sort { |(a, _), (b, _)| a <=> b }.map do |full, abbrs|
            [full, abbrs.first]
          end
        end

        def abbrs
          @abbrs ||= begin
            abbrs = Fias.short_names
            abbrs = abbrs.sort { |(a, _), (b, _)| b.size <=> a.size }
            abbrs = abbrs.map do |full, abbrs|
              [full, [abbrs].flatten]
            end
            Hash[abbrs]
          end
        end

        private
        def downcased_abbrs(abbrs)
          abbrs.map { |value| value.mb_chars.downcase.to_s }
        end

        def find_status(full_name)
          exps.map do |exp, *status|
            match = full_name.match(exp)
            if match && match[2].present?
              rate = rate_match(full_name, match)

              name = full_name.gsub(exp, ' ')
              name = strip_trailing(name)

              if name.present?
                [rate, name, *status]
              else
                [RATES[:status_equals_name], full_name]
              end
            end
          end
        end

        def rate_match(full_name, match)
          start_pos, end_pos = match.begin(2), match.end(3)

          ends_with   = end_pos == full_name.length
          starts_with = start_pos.zero?

          rate = 0

          rate += RATES[:starts]    if starts_with
          rate += RATES[:ends]      if ends_with
          rate += RATES[:lowercase] if not(capitalized?(match))

          rate
        end

        def capitalized?(match)
          match = [match[2], match[3]]
          match.any? { |value| value.try(:first).to_s =~ CAPITAL_LETTER }
        end

        def get_matching_result(results)
          results.compact!
          results.sort! { |a, b| b.first <=> a.first }
          max_rate, _ = results.first
          results.reject! { |rate, _| rate != max_rate }
          results.first
        end

        def exps
          @@exps ||= begin
            full_exps = abbrs.map do |full, abbrs|
              [/(\s|^)(#{Regexp.escape(full)})(\s|\.|$)/iu, full, *abbrs]
            end
            abbr_exps = abbrs.map do |full, abbrs|
              abbrs_or = abbrs.map { |a| Regexp.escape(a) }.join('|')
              [/(\s|^)(#{abbrs_or})?(\.|\s|$)/iu, full, *abbrs]
            end

            full_exps + abbr_exps
          end
        end

        def replace_exceptions!(name)
          name.tap do |name|
            EXCEPTIONS.each do |what, with|
              name.gsub!(what, with)
            end
          end
        end

        def strip_trailing(value)
          value.gsub(TRAILING_WHITESPACE, ' ').strip
        end

        CAPITAL_LETTER = /[А-ЯЁ]/u
        TRAILING_WHITESPACE = /\s+/

        RATES = {
          occurence: -1,
          ends: 10,
          starts: 100,
          lowercase: 100,
          status_equals_name: 1000
        }

        EXCEPTIONS = {
          'городского типа поселок' => 'поселок городского типа'
        }
      end
    end
  end
end
