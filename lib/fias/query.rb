module Fias
  class Query
    def initialize(params = {})
      @params = Params.new(params)
    end

    attr_reader :params
  end
end
