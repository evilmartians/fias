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

    def search(key)
      long = @index[Unicode.downcase(key)]
      return nil unless long
      [long, short_for(long), aliases_for(long)].flatten.compact
    end

    def short_for(long)
      @shorts[Unicode.downcase(long)]
    end

    def aliases_for(long)
      @aliases[Unicode.downcase(long)]
    end

    def search_exception(name)
      @exceptions[Unicode.downcase(name)]
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
