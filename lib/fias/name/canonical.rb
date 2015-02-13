module Fias
  module Name
    module Canonical
      class << self
        def canonical(name)
          result = search(name) || search_exception(name)
          result || fail("Unknown abbrevation: #{name}")
          fix_republic_case(result)
        end

        private

        def search(key)
          long = Fias.config.index[Unicode.downcase(key)]
          return nil unless long
          short = short_for(long)
          short_stripped = short_for(long).gsub(/\.$/, '')
          [long, short_stripped, short, aliases_for(long)].flatten.compact
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
      end

      REPUBLIC = 'республика'
    end
  end
end
