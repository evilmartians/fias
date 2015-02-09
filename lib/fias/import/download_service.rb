module Fias
  module Import
    module DownloadService
      def url
        url = fetch_url
        url ? url : 999
      end

      private

      def fetch_url
        response = HTTParty.post(
          'http://fias.nalog.ru/WebServices/Public/DownloadService.asmx',
          OPTIONS
        )

        matches =
          response.body.match(/<FiasCompleteDbfUrl>(.*)<\/FiasCompleteDbfUrl>/)

        matches[1] if matches
      end

      OPTIONS = {
        body: %(<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xsd="http://www.w3.org/2001/XMLSchema"
  xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
<soap:Body>
<GetLastDownloadFileInfo
  xmlns="http://fias.nalog.ru/WebServices/Public/DownloadService.asmx/" />
</soap:Body>
</soap:Envelope>
),
        headers: {
          'SOAPAction' => 'http://fias.nalog.ru/WebServices/Public/DownloadService.asmx/GetLastDownloadFileInfo',
          'Content-Type' => 'text/xml; encoding=utf-8'
        }
      }

      module_function :url, :fetch_url
    end
  end
end
