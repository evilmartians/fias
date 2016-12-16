require 'spec_helper'
require "savon/mock/spec_helper"

describe Fias::Import::DownloadService do
  include Savon::SpecHelper
  before(:all) { savon.mock! }
  after(:all)  { savon.unmock! }
  it 'parses url' do
    fixture = File.read('spec/fixtures/response.xml')
    savon.expects(:get_last_download_file_info).returns(fixture)
    response = new_client(raise_errors: false).call(:get_last_download_file_info)
    expect(response).to be_successful
    expect(response.http.body).to match(/fias_dbf.rar/)
  end

  def new_client(globals = {})
    defaults = {
        endpoint: 'http://example.com',
        namespace: 'http://v1.example.com',
        log: false
    }
    Savon.client defaults.merge globals
  end
end
