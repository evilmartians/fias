require 'spec_helper'

describe Fias::Import::RestoreParentId do
  let(:db) { Sequel.sqlite }
  let(:table) { db[:address_objects] }
  let(:records) { table.select_map([:id, :parent_id]).index_by(&:first) }

  subject { described_class.new(table) }

  before do
    db.create_table! :address_objects do
      primary_key :id
      column :aoguid, :string
      column :parentguid, :string
      column :parent_id, :integer
    end

    table.insert(id: 1, aoguid: 'g1')
    table.insert(id: 2, aoguid: 'g2')
    table.insert(id: 3, aoguid: 'g3', parentguid: 'g1')
    table.insert(id: 4, aoguid: 'g4', parentguid: 'g1')
    table.insert(id: 5, aoguid: 'g5', parentguid: 'g2')
  end

  it do
    subject.restore

    expect(records[1].last).to be_nil
    expect(records[2].last).to be_nil
    expect(records[3].last).to eq(1)
    expect(records[4].last).to eq(1)
    expect(records[5].last).to eq(2)
  end
end
