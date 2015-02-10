module Fias
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.join(File.dirname(__FILE__), '../../../tasks/db.rake')
      load File.join(File.dirname(__FILE__), '../../../tasks/download.rake')
    end
  end
end
