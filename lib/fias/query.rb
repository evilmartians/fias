module Fias
  module Query
    def initialize(params)
      @params = Params.new(params)
      @finder = Finder.new(
        @params.sanitized, method(:find), method(:ancestor_ids)
      )
    end

    attr_reader :params

    def perform
      assumption = @finder.assumption
    end

    protected

    def find(_tokens)
      fail NotImplementedError
    end
  end
end
