module Fias
  class AddressObject < ActiveRecord::Base
    self.table_name = "#{Rails.application.config.fias.prefix}_address_objects"
    self.primary_key = 'aoid'

    alias_attribute :name, :formalname

    # Родительские объекты (Ленобласть для Лодейнопольского района)
    # Для "проезд 1-й Конной Лахты 2-й" - Санкт-Петербург и Ленинград.
    # Блядь, 1-й проезд 2-й Конной Лахты, ебануться!
    # http://maps.yandex.ru/?text=%D0%A0%D0%BE%D1%81%D1%81%D0%B8%D1%8F%2C%20%D0%A1%D0%B0%D0%BD%D0%BA%D1%82-%D0%9F%D0%B5%D1%82%D0%B5%D1%80%D0%B1%D1%83%D1%80%D0%B3%2C%202-%D0%B9%20%D0%BF%D1%80%D0%BE%D0%B5%D0%B7%D0%B4%201-%D0%B9%20%D0%9A%D0%BE%D0%BD%D0%BD%D0%BE%D0%B9%20%D0%9B%D0%B0%D1%85%D1%82%D1%8B&sll=30.123296%2C60.007056&ll=30.123848%2C60.007475&spn=0.010085%2C0.006017&z=17&l=map
    has_many :parents,
      class_name: 'AddressObject',
      foreign_key: 'aoguid',
      primary_key: 'parentguid'

    # Дочерние объекты (например, улицы для города)
    has_many :children,
      class_name: 'AddressObject',
      primary_key: 'aoguid',
      foreign_key: 'parentguid'

    # Предыдущая историческая версия названия (Ленинград для Питера)
    belongs_to :next_version,
      class_name: 'AddressObject',
      primary_key: 'aoid',
      foreign_key: 'nextid'

    # Следующая историческая версия названия (Питер для Ленинграда)
    belongs_to :previous_version,
      class_name: 'AddressObject',
      primary_key: 'aoid',
      foreign_key: 'previd'

    # Актуальные записи (активные в настоящий момент)
    # Проверено, что livestatus уже достаточен для идентификации
    # актуальных объектов, вопреки показаниям вики.
    scope :actual, where(livestatus: 1)

    # Выбирает объекты определенного уровня, аргументы - символы из хеша
    # AOLEVELS
    scope :leveled, ->(*levels) {
      levels = Array.wrap(levels).map { |level| AOLEVELS[level] }
      where(aolevel: levels)
    }

    scope :sorted, order('formalname ASC')

    # Наименование типа объекта
    belongs_to :address_object_type,
      class_name: 'Fias::AddressObjectType',
      primary_key: 'shortname',
      foreign_key: 'scname'

    # Есть ли исторические варианты записи?
    def has_history?
      previd.present?
    end

    # Актуальный родитель. Для 1-го проезда 2-й Конной Лахты - только Питер.
    def parent
      parents.actual.first
    end

    def aolevel_sym
      AOLEVELS.key(aolevel)
    end

    # Коды уровня адресного объекта
    AOLEVELS = {
      region: 1, autonomy: 2, district: 3, city: 4,
      territory: 5, settlement: 6, street: 7,
      additional_territory: 90, additional_territory_slave: 91
    }
  end
end