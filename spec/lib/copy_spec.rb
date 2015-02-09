require 'spec_helper'

describe Fias::Import::Copy do
  let(:files) { Fias::Import::Dbf.new('spec/fixtures').files }
  let(:tables) { Fias::Import::Schema.new(files).tables }
  let(:table) { tables.slice('fias_actual_statuses') }
  let(:connection) {}

  subject do
    described_class.new(connection, table.keys.first, table.values.first)
  end

  it do
    subject.start
  end
end
