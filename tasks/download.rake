require 'fias/import'

namespace :fias do
  desc 'Returns lastest url of FIAS db (bundle exec rake fias:download | xargs wget)'
  task :download do
    url = Fias::Import::DownloadService.url

    if url
      puts url
    else
      puts 'An error occured during SOAP call'
      return 999
    end
  end
end