require 'spec_helper'

describe Fias::Import::Schema do
  let(:files) { Fias::Import::Dbf.new('spec/fixtures').files }

  subject { described_class.new(files, '_fias') }

  before do
    connection = double('connection')

    allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
    allow(connection).to receive(:raw_connection)
  end

  it 'returns schema' do
    expect(subject.schema).to include('_fias_house99')
    expect(subject.schema).to include('_fias_structure_statuses')
    expect(subject.schema).to include('_fias_actual_statuses')
  end

  it 'uuids' do
    stub_const("#{described_class.name}::UUID", house99: %w(aoguid))
    expect(subject.schema).to include('t.column "aoguid", :uuid')
  end

  it 'tables' do
    expect(subject.tables.size).to eq(3)
  end
end
