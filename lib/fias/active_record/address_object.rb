# encoding: utf-8
module Fias
  class AddressObject < ActiveRecord::Base
    # TODO: Тут надо понять как префикс передать
    if defined?(Rails)
      self.table_name = "#{Rails.application.config.fias.prefix}_address_objects"
    else
      self.table_name = "fias_address_objects"
    end

    self.primary_key = 'aoid'

    alias_attribute :name, :formalname
    alias_attribute :reference, :aoguid # UUID адресного объекта,
                                        # для Ленинграда и Петербурга одинаковы


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
    scope :with_types, includes(:address_object_type)

    # Полное наименование типа объекта (город, улица)
    belongs_to :address_object_type,
      class_name: '::Fias::AddressObjectType',
      foreign_key: 'shortname',
      primary_key: 'scname'

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

    # Название с сокращением / полным наименованием города
    # "г. Санкт-Петербург" / "город Санкт-Петербург"
    #
    #   full ? "Город"" : г.
    #   explicit == false ? "Дагестан" вместо "Республика Дагестан", но всегда
    #                       "Самарская область"
    def abbrevated(full = true, explicit = false)
      case aolevel_sym
      when :region
        # "Ханты-Мансийский Автономный округ - Югра"
        return name if regioncode == '86'

        no_shortname = shortname.blank? || (full && address_object_type.blank?)
        return name if no_shortname

        ending = name[-2..-1]

        # В конец ставить если кончается на -ая -ий или это Чувашия
        explicit_append = SHN_MUST_APPEND_TO_ENDINGS.include?(ending) ||
                          shortname == 'Чувашия'

        # Дописывать сокращение нужно если либо заставили - либо оно должно
        # быть по правилам русского языка
        must_abbrevate = explicit || explicit_append

        return name unless must_abbrevate

        abbr = full ? address_object_type.name : shortname

        # Точка не ставится для АО, Аобл или если это "Автономная область"
        abbr = "#{abbr}." unless shortname.in?(SHN_MUST_NOT_APPEND_DOT) || full

        if shortname.in?(SHN_PREPEND_BY_DEFAULT) && not(explicit_append)
          "#{abbr} #{name}"
        else
          # Сокращаются все длинные названия типов (Республика, Край),
          # кроме Чувашии и все короткие, кроме АО, Аобл
          if shortname != 'Чувашия'
            abbr = abbr.mb_chars.downcase if full || not(shortname.in?(SHN_NODCASE))
          end
          "#{name} #{abbr}"
        end
      else
        "#{shortname}. #{name}"
      end
    end

    # Коды уровня адресного объекта
    AOLEVELS = {
      region: 1, autonomy: 2, district: 3, city: 4,
      territory: 5, settlement: 6, street: 7,
      additional_territory: 90, additional_territory_slave: 91
    }

    # Дописывать сокращения обязательно, "Самарская" выглядит странно,
    # всегда должно быть "Самарская область", а "Дагестан" понятно и так.
    SHN_MUST_APPEND_TO_ENDINGS = %w(ая ий)
    SHN_MUST_NOT_APPEND_DOT = %w(край АО Чувашия) # Не дописывать точку к сокращению
    SHN_NODCASE = %w(АО Аобл Чувашия) # Не даункезить короткое название даже если оно в конце
    SHN_PREPEND_BY_DEFAULT = %w(Респ г) # Ставить в начало по-умолчанию
  end
end