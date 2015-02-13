require 'spec_helper'

describe Fias::Import::Copy do
  let(:name) { 'actual_statuses' }
  let(:files) { Fias::Import::Dbf.new('spec/fixtures').only(name) }
  let(:table_name) { "fias_#{name}".to_sym }
  let(:db) { double('db') }
  let(:raw_connection) { double('raw_connection') }

  subject { Fias::Import::Tables.new(db, files).copy.first }

  before do
    stub_const('Fias::Import::Tables::UUID', name.to_sym => %w(name))
  end

  context '#encode' do
    it do
      expect(PgDataEncoder::EncodeForCopy).to receive(:new).with(
        column_types: { 1 => :uuid }
      ).and_call_original

      subject.encode
    end
  end

  context '#copy' do
    let(:result) { double('result') }

    before do
      table_obj = double(table_name)
      expect(db).to receive(:[]).with(table_name).and_return(table_obj)
      expect(table_obj).to receive(:truncate)
      expect(db).to receive(:run).with(/SET client/)
      expect(db).to receive(:copy_into).with(
        :fias_actual_statuses, columns: [:actstatid, :name], format: :binary
      ).and_yield.and_yield
    end

    it do
      subject.encode
      subject.copy
    end
  end
end
