module Fias
  module Name
    module Append
      class << self
        def append(name, short_name)
          long, _, short, _ = Canonical.canonical(short_name)

          exception = Fias.config.exceptions[Unicode.downcase(name)]
          return exception.reverse if exception

          replacement = Fias.config.replacements[Unicode.downcase(name)]
          return replacement if replacement

          [concat(short, name), concat(long, name)]
        end

        private

        def concat(status, name)
          must_append?(name) ? "#{name} #{status}" : "#{status} #{name}"
        end

        def must_append?(name)
          ending = name[-2..-1]
          ENDINGS_TO_APPEND.include?(ending) || name =~ JUST_NUMBER
        end
      end

      ENDINGS_TO_APPEND = %w(ая ий ый)
      JUST_NUMBER = /^\d+([\-А-Яа-яе]{1,3})?$/u
    end
  end
end
