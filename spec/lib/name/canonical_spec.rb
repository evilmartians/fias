require 'spec_helper'

describe Fias::Name::Canonical do
  context '#canonical' do
    {
      'ул' => %w(улица ул ул.),
      'Улица' => %w(улица ул ул.),
      'микр' => %w(микрорайон мкр мкр. мкрн микр),
      'микрорайон' => %w(микрорайон мкр мкр. мкрн микр),
      'АО' => ['автономный округ', 'АО', 'АО'],
      'Аобл' => ['автономная область', 'Аобл', 'Аобл'],
      'республика' => %w(Республика Респ Респ.),
      'Чувашия' => ['Чувашская Республика - Чувашия', 'Чувашия']
    }.each do |to, normalized|
      it "#{to} must become #{normalized.inspect}" do
        expect(described_class.canonical(to)).to eq(normalized)
      end
    end
  end
end
