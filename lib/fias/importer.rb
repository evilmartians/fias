module Fias
  module Importer
    # Фактори-метод, возвращает ссылку на объект импортера
    # Принимает параметры:
    #   :adapter - название адаптера
    #   :connection - прямое соединение с базой данных (connection.raw_connection)
    def self.build(options = {})
      adapter    = options.delete(:adapter) ||
                   ActiveRecord::Base.connection_config[:adapter]

      connection = options.delete(:connection) ||
                   ActiveRecord::Base.connection.raw_connection

      case adapter
        when 'postgresql'
          Pg.new(
            connection,
            options
          )
        when 'sqlite3'
          Sqlite.new(
            connection,
            options
          )
        else
          raise 'Only postgres & sqlite supported now, fork'
      end
    end
  end
end