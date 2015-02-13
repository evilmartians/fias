require 'spec_helper'

describe Fias::Import::DownloadService do
  it 'parses url' do
    stub_request(
      :post,
      'http://fias.nalog.ru/WebServices/Public/DownloadService.asmx'
    ).with(described_class::OPTIONS).to_return(
      status: 200,
      body: '<FiasCompleteDbfUrl>http://www.ya.ru</FiasCompleteDbfUrl>'
    )

    expect(described_class.url).to eq('http://www.ya.ru')
  end
end
