module Fias
  module Query
    def initialize(params)
      @params = Params.new(params)
      @finder = Finder.new(@params.sanitized, method(:find))
    end

    attr_reader :params

    def perform
      assumption = @finder.assumption
    end

    protected

    def find(_tokens)
      fail NotImplementedError
#
#          where.overlap(tokens: search_tokens).
#          visible.
#          pluck(*FIELDS)

    end
  end
end
