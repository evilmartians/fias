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
=begin
  it 'must not resanitize already sanitized parts' do
    sanitized = Addressing::Parts.sanitize(
      city: 'г Краснодар', street: 'Ушинского'
    )
    expect(sanitized).to be_present
    expect(Addressing::Parts.sanitize(sanitized)).to eq(sanitized)
  end

  it 'must create correct address string from a parts' do
    address = Addressing::Parts.address_from_parts(
      house_number: 33,
      city: 'Санкт-Петербург',
      street: 'Искровский пр.'
    )
    expect(address).to eq('33, проспект Искровский, город Санкт-Петербург')
  end

  it 'must create correct address string from a full address' do
    address = Addressing::Parts.address_from_parts(
      house_number: 33,
      address: 'Искровский проспект, город Санкт-Петербург'
    )
    expect(address).to eq('33, Искровский проспект, город Санкт-Петербург')
  end
=end
end
