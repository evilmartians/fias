require 'spec_helper'

describe Fias::Import::Schema do
  let(:files) { Fias::Import::Dbf.new('spec/fixtures').files }

  subject { described_class.new(files, '_fias') }

  it 'returns schema' do
    expect(subject.schema).to include('_fias_house99')
    expect(subject.schema).to include('_fias_structure_statuses')
    expect(subject.schema).to include('_fias_actual_statuses')
  end
end
