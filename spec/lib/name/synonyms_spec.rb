require 'spec_helper'

describe Fias::Name::Synonyms do
  context '#expand' do
    {
      '2-я Советская улица' => [
        %w(
          2й 2-й 2я 2-я 2е 2-е 2ая 2-ая 2ий 2-ий 2ый 2-ый
          2ой 2-ой 2ые 2-ые 2ое 2-ое 2го 2-го 2
        ),
        %w(советская),
        %w(улица)],
      '2-ой проспект им. 50 лет Николая Лавочкина героя соцтруда улица' => [
        %w(
          2й 2-й 2я 2-я 2е 2-е 2ая 2-ая 2ий 2-ий 2ый 2-ый
          2ой 2-ой 2ые 2-ые 2ое 2-ое 2го 2-го 2
        ),
        ['проспект'],
        ['им', 'имени', 'им.', ''],
        ['50-летия', '50-лет', '50 летия', '50 лет', '50-летие', '50 летие'],
        ['николая', ''],
        ['лавочкина'],
        ['героя', ''],
        ['соцтруда', 'соц.труда', ''],
        ['улица']
      ],
      'ул. И.А.Покрышкина' => [
        ['ул.'], ['и.а.', ''], ['покрышкина']
      ]
    }.each do |name, synonyms|
      it(name) do
        expect(described_class.expand(name)).to eq(synonyms)
      end
    end
  end

  it '#forms' do
    expect(described_class.forms('им. И.П.Павлова')).to eq(
      [
        'и.п. им павлова',
        'им павлова',
        'и.п. имени павлова',
        'имени павлова',
        'и.п. им. павлова',
        'им. павлова',
        'и.п. павлова',
        'павлова'
      ]
    )
  end
end