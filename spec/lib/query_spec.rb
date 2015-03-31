require 'spec_helper'

describe Fias::Query do
  context '#perform' do
    context 'by default' do
      subject { UndefinedQuery.new(city: 'Санкт-Петербург') }

      it 'raises error' do
        expect { subject.perform }.to raise_error(NotImplementedError)
      end
    end

    context 'with provided #find method' do
      YAML.load_file('spec/fixtures/query.yml').each do |query, indexes|
        query = query.symbolize_keys
        it "looks up #{query.inspect}" do
          result = TestQuery.new(query).perform
          result = result.map(&:last).sort_by { |r| r[:id] }

          expected = SHORTCUTS.values_at(*indexes).sort_by { |r| r[:id] }

          expect(result.first(expected.size)).to eq(expected)
        end
      end
    end
  end
end
