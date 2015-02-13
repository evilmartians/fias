module Fias
  class Config
    def initialize
      @longs = {}
      @shorts = {}
      @aliases = {}
      @dots = {}
      @search = {}
      @append_exceptions = {}

      yield(self)
    end

    def canonical(long, short, options = {})
      aliases = options.delete(:aliases) || []

      dc_long = Unicode.downcase(long)
      dc_short = Unicode.downcase(short)

      @longs[dc_short] = long
      @shorts[dc_long] = short
      @aliases[dc_long] = aliases

      @search[dc_long] = long
      @search[dc_short] = long if dc_short != dc_long

      aliases.each { |a| @search[a] = long }
      @dots[dc_short] = options.delete(:dot).nil?
    end

    def exception_for_append(long, short)
      @append_exceptions[Unicode.downcase(short)] = [short, long]
      @append_exceptions[Unicode.downcase(long)] = [short, long]
    end

    def search(name)
      name = Unicode.downcase(name)
      long = @search[name]
      return nil unless long
      [long, short_for(long), aliases_for(long)].flatten.compact
    end

    def short_for(long)
      @shorts[Unicode.downcase(long)]
    end

    def aliases_for(long)
      @aliases[Unicode.downcase(long)]
    end

    def need_dot?(long)
      @dots[Unicode.downcase(long)]
    end

    def search_append_exception(name)
      @append_exceptions[Unicode.downcase(name)]
    end
  end
end
