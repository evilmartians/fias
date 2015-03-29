require 'spec_helper'

describe Fias::Query do
  context '#initialize/#sanitized' do
    YAML.load_file('spec/fixtures/query_sanitization.yml').each do |pair|
      from, to = pair
      from.symbolize_keys!
      to.symbolize_keys!

      it from.values.to_s do
        expect(described_class.new(from).sanitized).to eq(to)
      end
    end
  end
end

