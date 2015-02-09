require 'spec_helper'

describe Fias::Import::Schema do
  let(:files) { Fias::Import::Dbf.new('spec/fixtures').files }

  subject { described_class.new(files, '_fias') }

  it 'returns schema' do
    expect(subject.schema).to include('_fias_house99')
    expect(subject.schema).to include('_fias_structure_statuses')
    expect(subject.schema).to include('_fias_actual_statuses')
  end

  it 'alters pg' do
    stub_const("#{described_class.name}::PG_UUID", house99: %w(aoguid))
    expect(subject.pg).to include('ALTER TABLE _fias_house99')
    expect(subject.pg).to include('ALTER COLUMN aoguid')
  end
end
