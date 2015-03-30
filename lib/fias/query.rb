module Fias
  module Query
    def initialize(params)
      @params = Params.new(params)
      @finder = Finder.new(@params, method(:find))
    end

    attr_reader :params

    def perform
      assumption = @finder.assumption
      estimate(assumption)
    end

    protected

    def find(_tokens)
      fail NotImplementedError
    end

    def estimate(assumption)
      chains = estimate_chains(assumption)
      reject_invalid_chains(chains)
    end

    def estimate_chains(assumption)
      assumption
        .map { |chain| [rate(chain), chain.first] }
        .sort_by(&:first)
        .reverse
    end

    def reject_invalid_chains(chains)
      return chains if chains.empty?
      highest_rate = chains.first.first
      chains.keep_if { |c| c.first == highest_rate }
    end

    def rate(chain)
      Estimate.new(@params, chain).estimate
    end
  end
end
