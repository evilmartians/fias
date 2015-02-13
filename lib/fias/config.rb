module Fias
  class Config
    def initialize
      @index = {}
      @longs = {}
      @shorts = {}
      @aliases = {}
      @exceptions = {}

      yield(self)
    end

    attr_reader :index, :longs, :shorts, :aliases, :exceptions

    def add_name(long, short, options = {})
      aliases = options.delete(:aliases) || []

      @longs[Unicode.downcase(short)] = long
      @shorts[Unicode.downcase(long)] = short
      @aliases[Unicode.downcase(long)] = aliases

      populate_index(long, short, aliases)
    end

    def add_exception(long, short)
      @exceptions[Unicode.downcase(short)] = [short, long]
      @exceptions[Unicode.downcase(long)] = [short, long]
    end

    private

    def populate_index(long, short, aliases)
      long_downcase = Unicode.downcase(long)
      short_downcase = Unicode.downcase(short)

      @index[long_downcase] = long

      if long_downcase != short_downcase
        @index[short_downcase] = long
        @index[short_downcase[0..-2]] = long if short_downcase[-1] == '.'
      end

      aliases.each { |al| @index[Unicode.downcase(al)] = long }
    end
  end
end
