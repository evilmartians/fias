module Fias
  module Import
    module DownloadService
      def url
        client = Savon.client(wsdl: 'http://fias.nalog.ru/WebServices/Public/DownloadService.asmx?WSDL')
        info = client.call(:get_last_download_file_info)
                   .to_hash[:get_last_download_file_info_response][:get_last_download_file_info_result]
        info[:fias_complete_dbf_url]
      end

      module_function :url
    end
  end
end
