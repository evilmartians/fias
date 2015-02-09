require 'spec_helper'

describe Fias::Import::Copy do
  let(:files) { Fias::Import::Dbf.new('spec/fixtures').files }
  let(:tables) { Fias::Import::Schema.new(files).tables }
  let(:table_name) { 'fias_actual_statuses' }
  let(:table) { tables.slice(table_name) }
  let(:connection) { double('connection') }
  let(:raw_connection) { double('raw_connection') }
  let(:pool) { double('pool') }

  subject do
    described_class.new(table.keys.first, table.values.first)
  end

  before do
    checkout = double('checkout')

    allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
    allow(connection).to receive(:pool).and_return(pool)
    allow(pool).to receive(:checkout).and_return(checkout)
    allow(checkout).to receive(:raw_connection).and_return(raw_connection)
  end

  it('#encode') { subject.encode }

  context '#import' do
    let(:result) { double('result') }

    before do
      expect(connection).to receive(:execute).with(/TRUNCATE/).once
      expect(raw_connection).to receive(:exec).with(/COPY #{table_name}/).once
      expect(raw_connection).to receive(:put_copy_data).with(/PGCOPY/)
      expect(raw_connection).to receive(:put_copy_end).once
      expect(raw_connection).to receive(:get_result).and_return(result).once
      expect(result).to receive(:result_status)
    end

    it 'succeeds' do
      expect(result).to receive(:res_status).and_return('PGRES_COMMAND_OK')
      expect(raw_connection).to receive(:get_result).and_return(nil).once

      subject.encode
      subject.perform
    end

    it 'fails' do
      expect(result).to receive(:res_status).and_return('NO')

      subject.encode
      expect { subject.perform }.to raise_error
    end
  end
end
