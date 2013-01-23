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
    alias_attribute :id, :aoid

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

    # Предыдущие исторические версии названия (Ленинград для Питера)
    # Может быть несколько, если произошло слияние
    has_many :previous_versions,
      class_name: 'AddressObject',
      foreign_key: 'aoid',
      primary_key: 'previd'

    # Следующая исторические версии названия (Питер для Ленинграда)
    # Может быть несколько, если произошло разделение
    has_many :next_versions,
      class_name: 'AddressObject',
      foreign_key: 'aoid',
      primary_key: 'nextid'

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
    scope :matching, ->(name) {
      scope = if self.connection.adapter_name
        where(%{ "formalname" @@ ? OR ? @@ "formalname"}, name, name)
      else
        where('formalname LIKE ?', "%#{name}%")
      end

      # Первыми идут центральные и крупные поселения
      scope.order('aolevel ASC, centstatus DESC')
    }

    # Значимые поселения
    scope :central, where('centstatus > 0')

    # Полное наименование типа объекта (город, улица)
    belongs_to :address_object_type,
      class_name: '::Fias::AddressObjectType',
      foreign_key: 'shortname',
      primary_key: 'scname'

    def has_history?
      previd.present?
    end

    def actual?
      livestatus == 1
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
    # Для работы метода требуется загрузить таблицу :address_object_types
    #
    # Параметр - режим:
    #   :obviously - очевидный режим". В этом режиме "Дагестан" вместо
    #                "Республика Дагестан", "АО" вместо "Автономная область",
    #                но всегда "Краснодарский край"
    #   :short     - дописываются "г." и "респ."
    #   :long      - дописываются "город" и "Республика"
    #
    # Пример:
    #   .abbrevated(:obviously)      # Тульская область, Хакасия, Еврейская Аобл.
    #   .abbrevated(:short)          # Тульская область, Респ. Хакасия,  Еврейская Аобл.
    #   .abbrevated(:long)           # Тульская область, Республика Хакасия, Еврейская автономная область
    def abbrevated(mode = :obviously)
      return name if address_object_type.blank? || shortname.blank?

      case aolevel_sym
      when :region
        # "Ханты-Мансийский Автономный округ - Югра"
        return name if regioncode == '86'

        ending = name[-2..-1]

        # Если название кончается на -ая -ий - по правилам русского языка
        # нужно дописать в конец "область", "край"
        must_append = SHN_MUST_APPEND_TO_ENDINGS.include?(ending) ||
                      shortname == 'Чувашия'

        must_abbrevate = must_append ||
                         shortname == 'Чувашия' ||
                         mode != :obviously

        return name unless must_abbrevate

        abbr = case mode
          when :short
            shortname
          when :long
            address_object_type.name
          when :obviously
            if SHN_LEAVE_SHORTS_INTACT.include?(shortname)
              shortname
            else
              address_object_type.name
            end
        end

        # Точка не ставится для АО, края, Чувашии и длинных названий
        abbr = "#{abbr}." if mode == :short && not(shortname.in?(SHN_MUST_NOT_APPEND_DOT))

        if not(must_append) && must_abbrevate
          "#{abbr} #{name}"
        else
          # "Республика" => "республика", но "АО" остается
          abbr = abbr.mb_chars.downcase if not(shortname.in?(SHN_LEAVE_SHORTS_INTACT))
          "#{name} #{abbr}"
        end
      else
        abbr = if full
          address_object_type.try(:name)
        else
          shortname
        end
        "#{abbr} #{name}"
      end
    end

    class << self
      # Подробное описание см. в README
      # TODO: OPERSTATUS
      def match_existing(scope, fias_key_accessor, title_field_accessor, &block)
        scope.find_each do |record|
          aoid = record.send(fias_key_accessor)
          title = record.send(title_field_accessor)

          if aoid.present?
            match = scoped.find_by_aoid(aoid)

            if match.present?
              unless match.actual?
                next_versions = match.next_versions

                if next_versions.empty?
                  yield(:deleted, record, match)
                elsif next_versions.count == 1
                  next_version = next_versions.first
                  previous_versions_of_current = next_version.previous_versions

                  if previous_versions_of_current.count == 1
                    yield(:updated, record, next_version)
                  else
                    yield(:joined, record, next_version, previous_versions_of_current)
                  end
                elsif next_versions.count > 1
                  yield(:split, record, next_versions)
                end
              end
            end
          else
            matches = scoped.matching(title)
            yield(:match, record, *matches)
          end
        end
      end

      def match_missing(scope, address_object_key_field, &block)
        scoped.each do |address_object|
          unless scope.where(address_object_key_field => address_object.aoid).exists?
            yield(:created, nil, address_object)
          end
        end
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
    SHN_LEAVE_SHORTS_INTACT = %w(АО Аобл Чувашия) # В очевидном режиме не разворачивать "АО" в "Автономная область"
  end
end