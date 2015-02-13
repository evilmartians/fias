module Fias
  module Name
    module Short
      class << self
        def canonical(name)
          result = search(name) || search_exception(name)
          result || fail("Unknown abbrevation: #{name}")
          fix_republic_case(result)
        end

        def append(name, short_name)
          long, short, _ = canonical(short_name)

          exception = search_exception(name)
          return exception.reverse if exception

          [concat(short, name), concat(long, name)]
        end

        private

        def search(key)
          long = Fias.config.index[Unicode.downcase(key)]
          return nil unless long
          [long, short_for(long), aliases_for(long)].flatten.compact
        end

        def short_for(long)
          Fias.config.shorts[Unicode.downcase(long)]
        end

        def aliases_for(long)
          Fias.config.aliases[Unicode.downcase(long)]
        end

        def search_exception(name)
          Fias.config.exceptions[Unicode.downcase(name)]
        end

        def fix_republic_case(canonical)
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
