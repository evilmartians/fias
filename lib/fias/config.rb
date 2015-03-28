module Fias
  class Config
    def initialize
      @index = {}
      @longs = {}
      @shorts = {}
      @aliases = {}
      @exceptions = {}

      yield(self)

      finalize_index
    end

    attr_reader :index, :longs, :shorts, :aliases, :exceptions

    def add_name(long, short, aliases = [])
      @longs[Unicode.downcase(short)] = long
      @shorts[Unicode.downcase(long)] = short
      @aliases[Unicode.downcase(long)] = aliases

      populate_index(long, short, aliases)
    end

    def add_exception(long, short)
      @exceptions[Unicode.downcase(short)] = [long, short]
      @exceptions[Unicode.downcase(long)] = [long, short]
    end

    private

    def populate_index(long, short, aliases)
      long_downcase = Unicode.downcase(long)
      short_downcase = Unicode.downcase(short)

      populate_long_permutations(long)

      if long_downcase != short_downcase
        @index[short_downcase] = long
        @index[short_downcase[0..-2]] = long if short_downcase[-1] == '.'
      end

      aliases.each { |al| @index[Unicode.downcase(al)] = long }
    end

    def populate_long_permutations(long)
      Unicode.downcase(long).split(' ').permutation.each do |variant|
        @index[variant.join(' ')] = long
      end
    end

    def finalize_index
      @index = @index.sort_by { |key, _| key.size }.reverse
      @index = Hash[*@index.flatten]
    end

    LETTERS = /[а-яА-ЯёЁA-Za-z]/ui
  end
end
