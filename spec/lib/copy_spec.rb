require 'spec_helper'

describe Fias::Import::Copy do
  let(:name) { 'actual_statuses' }
  let(:files) { Fias::Import::Dbf.new('spec/fixtures').only(name) }
  let(:tables) { Fias::Import::Schema.new(files).tables }
  let(:table_name) { "fias_#{name}" }
  let(:raw_connection) { double('raw_connection') }

  subject { tables.first }

  before do
    stub_const('Fias::Import::Schema::UUID', name.to_sym => %w(name))

    connection = double('connection')

    allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
    allow(connection).to receive(:raw_connection).and_return(raw_connection)
  end

  context '#encode' do
    it do
      expect(PgDataEncoder::EncodeForCopy).to receive(:new).with(
        column_types: { 1 => :uuid }
      ).and_call_original

      subject.encode
    end
  end

  context '#import' do
    let(:result) { double('result') }

    before do
      expect(raw_connection).to receive(:exec).with(/TRUNCATE/).once
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
