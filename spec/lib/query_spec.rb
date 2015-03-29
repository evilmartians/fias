require 'spec_helper'

describe Fias::Query do
  context '#perform' do
    context 'when not overrided' do
      subject { UndefinedQuery.new(city: 'Санкт-Петербург') }

      it 'raises error' do
        expect { subject.perform }.to raise_error(NotImplementedError)
      end
    end

    context 'when overrided' do

    end
  end
end
