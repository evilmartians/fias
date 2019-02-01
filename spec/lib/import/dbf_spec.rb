require 'spec_helper'

describe Fias::Import::Dbf do
  subject { described_class.new('spec/fixtures') }

  context '#initialize' do
    it 'fails without files' do
      expect { described_class.new('foo') }.to raise_error(ArgumentError)
    end

    it 'returns correct file list' do
      expect(subject.files.keys).to eq(
        [:actual_statuses, :structure_statuses, :nordoc99]
      )
      expect(subject.files.values).to all(be_present)
      expect(subject.files.values).to all(be_kind_of(DBF::Table))
    end
  end

  context '#only' do
    it 'returns only houses' do
      expect(subject.only(:nordocs).keys).to eq([:nordoc99])
      expect(subject.only(:address_objects, :structure_statuses).keys).to eq(
        [:structure_statuses]
      )
    end
  end
end
