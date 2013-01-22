module Fias
  # Класс для доступа к DBF-файлам ФИАС.
  #
  # Пример:
  #   wrapper = Fias::DbfWrapper.new('tmp/fias')
  #   wrapper.address_objects.record_count
  #   wrapper.address_objects.each { |record| record.attributes }
  #
  # TODO: Добавить в инишилайзер tables, чтобы при создании проверять
  # их наличие в базе
  class DbfWrapper
    # Открывает DBF-файлы ФИАСа
    def initialize(pathspec)
      unless Dir.exists?(pathspec)
        raise ArgumentError, 'FIAS database path does not exists'
      end
      self.pathspec = pathspec

      DBF_ACCESSORS.each do |accessor, dbf_name|
        filename = File.join(pathspec, dbf_name)

        if File.exists?(filename)
          dbf = DBF::Table.new(filename, nil, DEFAULT_ENCODING)
          send("#{accessor}=", dbf)
        end
      end
    end

    # Возвращает хеш {аксессор dbf-таблицы => таблица}
    # На входе массив названий таблиц (строки)
    def tables(*only)
      only = only.first if only.first.is_a?(Array)
      only = only.map(&:to_s)

      hash = DBF_ACCESSORS.keys.map do |accessor|
        accessor_s = accessor.to_s
        is_houses = only.include?('houses') && accessor_s.starts_with?('house')

        if only.include?(accessor_s) || is_houses
          [accessor, send(accessor)]
        end
      end
      Hash[*hash.compact.flatten]
    end

    # { house01: "HOUSE01"..house99: "HOUSE99" }
    HOUSES_ACCESSORS = Hash[*(1..99).map { |n|
      [("house%0.2d" % n).to_sym, "HOUSE%0.2d.dbf" % n]
    }.flatten]

    # Таблица соответствий аттрибутов класса DBF-файлам
    DBF_ACCESSORS = {
      address_object_types: 'SOCRBASE.DBF',
      current_statuses: 'CURENTST.DBF',
      actual_statuses: 'ACTSTAT.DBF',
      operation_statuses: 'OPERSTAT.DBF',
      center_statuses: 'CENTERST.DBF',
      interval_statuses: 'INTVSTAT.DBF',
      estate_statues: 'ESTSTAT.DBF',
      structure_statuses: 'STRSTAT.DBF',
      address_objects: 'ADDROBJ.DBF',
      house_intervals: 'HOUSEINT.DBF',
      landmarks: 'LANDMARK.DBF'
    }.merge(
      HOUSES_ACCESSORS
    )

    DEFAULT_ENCODING = Encoding::CP866

    attr_reader   *DBF_ACCESSORS.keys
    attr_reader   :houses

    private
    attr_accessor :pathspec
    attr_writer   *DBF_ACCESSORS.keys
    attr_writer   :houses
  end
end