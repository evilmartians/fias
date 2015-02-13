require 'spec_helper'

describe Fias::Import::Tables do
  let(:files) { Fias::Import::Dbf.new('spec/fixtures').files }
  let(:db) { double('db') }

  subject { described_class.new(db, files, '_fias') }

  it '#create' do
    stub_const('Fias::Import::Tables::UUID', actual_statuses: %w(name))

    expect(db).to receive(:create_table).with(:_fias_actual_statuses).and_yield
    expect(db).to receive(:create_table).with(:_fias_nordoc99)
    expect(db).to receive(:create_table).with(:_fias_structure_statuses)

    expect(subject).to receive(:primary_key).with(:id)
    expect(subject).to receive(:column).with(:name, :uuid)
    expect(subject).to receive(:column).with(:actstatid, :float)

    expect { subject.create }.to_not raise_error
  end

  it '#copy' do
    expect(subject.copy.size).to eq(3)
  end
end
