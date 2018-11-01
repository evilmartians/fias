module Fias
  class Config
    def initialize
      @index = {}
      @longs = {}
      @shorts = {}
      @aliases = {}
      @exceptions = {}
      @proper_names = []
      @replacements = {}
      @synonyms = []
      @synonyms_index = {}
      yield(self)
      finalize_index
    end

    attr_reader :index, :longs, :shorts, :aliases, :exceptions, :replacements
    attr_reader :proper_names, :synonyms, :synonyms_index

    def add_name(long, short, aliases = [])

      @index
      @longs[Unicode.downcase(short)] = long
      @shorts[Unicode.downcase(long)] = short
      @aliases[Unicode.downcase(long)] = aliases
      populate_index(long, short, aliases)
    end

    def add_replacement(target, value)
      @replacements[Unicode.downcase(target)] = value
    end

    def add_exception(long, short) # Югра и тд
      @exceptions[Unicode.downcase(short)] = [long, short]
      @exceptions[Unicode.downcase(long)] = [long, short]
    end

    def add_proper_name(name) #различные имена собственные
      @proper_names << name
    end

    def add_synonym(*names) #Различные прилагательные
      @synonyms << names
      populate_synonyms_index(names)
    end

    private

    def populate_index(long, short, aliases)
      long_downcase = Unicode.downcase(long)
      short_downcase = Unicode.downcase(short)
      populate_long_permutations(long)
      @index[short_downcase] = []
      if long_downcase != short_downcase
        @index[short_downcase] << long
        @index[short_downcase[0..-2]] = [] if @index[short_downcase[0..-2]].nil? && short_downcase[-1] == '.'
        @index[short_downcase[0..-2]] << long if short_downcase[-1] == '.'
      else
        @index[short_downcase] << long
      end
      @index[short_downcase]
      aliases.each { |al|
        @index[Unicode.downcase(al)] = []
        @index[Unicode.downcase(al)] << long
      }

    end

    def populate_long_permutations(long)  #разбивает длинный вариант
      Unicode.downcase(long).split(' ').permutation.to_s
      Unicode.downcase(long).split(' ').permutation.each do |variant|
        @index[variant.join(' ')] = []
        @index[variant.join(' ')] << long
      end
    end

    def finalize_index
      @index = @index.sort_by { |key, _| key.size }.reverse # от смаого длинного соркащенного имени к самому короткому
      @index = Hash[@index]
    end

    def populate_synonyms_index(names)
      names.each { |name| @synonyms_index[name] = names }
    end
  end
end