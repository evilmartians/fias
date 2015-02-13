module Fias
  module Name
    module Short
      class << self
        def canonical(name)
          result = Fias.config.search(name)
          result || fail("Unknown abbrevation: #{name}")
          apply_republic_exception(result)
        end

        def append(name, short_name)
          long, short, _ = canonical(short_name)

          append_exception = Fias.config.search_append_exception(name)
          return append_exception if append_exception

          [
            concat(short, name),
            concat(long, name)
          ]
        end

        private

        def apply_republic_exception(canonical)
          return canonical unless canonical[0] == REPUBLIC
          canonical.map { |n| Unicode.upcase(n[0]) + n[1..-1] }
        end

        def concat(status, name)
          must_append?(name) ? "#{name} #{status}" : "#{status} #{name}"
        end

        def must_append?(name)
          ending = name[-2..-1]
          ENDINGS_TO_APPEND.include?(ending) || name =~ JUST_NUMBER
        end

        REPUBLIC = 'республика'
        ENDINGS_TO_APPEND = %w(ая ий ый)
        JUST_NUMBER = /^\d+([\-А-Яа-яе]{1,3})?$/u
      end
    end
  end
end
