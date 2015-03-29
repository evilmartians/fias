require 'spec_helper'

describe Fias::Query do
  context '#perform' do
    subject { UndefinedQuery.new(city: 'Санкт-Петербург') }

    it 'raises error' do
      expect { subject.perform }.to raise_error(NotImplementedError)
    end
  end
end
