require 'spec_helper'

describe Fias::Name::Append do
  context '#append' do
    YAML.load_file('spec/fixtures/status_append.yml').each do |item|
      name, toponym = *item.first
      short, long = *item.slice(1..-1)

      it "#{toponym} #{name} must generate #{short} and #{long}" do
        expect(described_class.append(name, toponym)).to eq([short, long])
      end
    end
  end
end
