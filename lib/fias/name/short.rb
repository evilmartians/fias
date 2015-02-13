module Fias
  module Name
    module Short
      class << self
        def canonical(name)
          name = Unicode.downcase(name)
          canonical = find_entry_for(name)
          canonical || fail("Unknown abbrevation: #{name}")
          apply_republic_exception(canonical)
        end

        def append(name, short_name)
          long, short, _ = canonical(short_name)

          return CHUVASHIA if chuvashia?(long, short)
          return UGRA if ugra?(name)

          [
            concat(dotted(long, short), name),
            concat(long, name)
          ]
        end

        private

        def find_entry_for(name)
          short_names = Fias.short_names[name]
          return [name] + [short_names].flatten if short_names

          full_name = Fias.full_names[name]
          return [full_name, Fias.short_names[full_name]] if full_name
        end

        def apply_republic_exception(canonical)
          return canonical unless canonical[0] == REPUBLIC
          canonical.map { |n| Unicode.upcase(n[0]) + n[1..-1] }
        end

        def chuvashia?(*args)
          args.any? { |arg| arg == CHUVASHIA.first }
        end

        def ugra?(name)
          name == UGRA.first
        end

        def concat(status, name)
          must_append?(name) ? "#{name} #{status}" : "#{status} #{name}"
        end

        def must_append?(name)
          ending = name[-2..-1]
          ENDINGS_TO_APPEND.include?(ending) || name =~ JUST_NUMBER
        end

        def dotted(long, short)
          return short unless dotable?(long, short)
          "#{short}."
        end

        def dotable?(long, short)
          !UNDOTABLE.include?(short) ||
            !short.include?('-') ||
            !Unicode.downcase(short) == Unicode.downcase(long)
        end

        REPUBLIC = 'республика'
        CHUVASHIA = [
          'Чувашия',
          'Чувашская Республика - Чувашия'
        ]
        UGRA = [
          'Ханты-Мансийский Автономный округ - Югра',
          'Ханты-Мансийский Автономный округ - Югра'
        ]
        ENDINGS_TO_APPEND = %w(ая ий ый)
        UNDOTABLE = %w(АО Аобл Чувашия) + [UGRA.first]
        JUST_NUMBER = /^\d+([\-А-Яа-яе]{1,3})?$/u
      end
    end
  end
end
