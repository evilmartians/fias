module Fias
  class << self
    attr_reader :config

    def configure(&block)
      @config = Config.new(&block)
    end

    def indivisible_words
      @indivisible_words ||=
        config
        .synonyms
        .flatten
        .find_all { |w| w.include?(' ') }
        .sort_by(&:size)
        .reverse
        .freeze
    end

    def word
      @word ||=
        /(#{ANNIVESARIES}|#{indivisible_words.join('|')}|[#{LETTERS}\"\'\d\.\)\(\/\-]+)(\s|\,|$)/ui
    end
  end

  LETTERS        = /[а-яА-ЯёЁA-Za-z]/ui
  ANNIVESARIES   = /(\d+)(\s\-|\-|\s)лет(ия)?/ui
  INITIAL        = /#{Fias::LETTERS}{1,2}\./ui
  INITIALS       = /(#{INITIAL}#{INITIAL}(#{INITIAL})?)(.+|$)/ui
  SINGLE_INITIAL = /(\.|\s|^)(#{Fias::LETTERS}{1,3}\.)(.+|$)/ui
  FEDERAL_CITIES = ['Москва', 'Санкт-Петербург', 'Севастополь', 'Байконур']
end

gem 'dbf', '=3.1.0'

require 'unicode'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/hash/keys'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/array/wrap'
require 'dbf'
require 'httparty'
require 'pg_data_encoder'
require 'fias/version'
require 'fias/config'
require 'fias/import/dbf'
require 'fias/import/tables'
require 'fias/import/download_service'
require 'fias/import/copy'
require 'fias/import/restore_parent_id'
require 'fias/name/canonical'
require 'fias/name/append'
require 'fias/name/extract'
require 'fias/name/house_number'
require 'fias/name/split'
require 'fias/name/synonyms'
require 'fias/query'
require 'fias/query/params'
require 'fias/query/finder'
require 'fias/query/estimate'
require 'fias/railtie' if defined?(Rails)

Fias.configure do |config|
  config.add_name('автономный округ', 'Аокр.',['А.О.'])
  config.add_name('автономная область', 'АО',['А.обл.', 'Аобл.'])
  config.add_name('город', 'г.')
  config.add_name('край', 'край')
  config.add_name('область', 'обл.')
  config.add_name('округ', 'округ')
  config.add_name('республика', 'Респ.')
  config.add_name('поселение', 'п.')
  config.add_name('район', 'р-н.')
  config.add_name('территория', 'тер.')
  config.add_name('улус', 'у.')
  config.add_name('волость', 'волость')
  config.add_name('дачный поселок', 'дп.')
  config.add_name('курортный поселок', 'кп.')
  config.add_name('массив', 'массив')
  config.add_name('поселок', 'п.', %w(пос посёлок))
  config.add_name('почтовое отделение', 'п/о')
  config.add_name('поселок городского типа', 'пгт')
  config.add_name('рабочий поселок', 'рп')
  config.add_name('сельская администрация', 'с/а.')
  config.add_name('сельское муниципальное образо', 'с/мо.')
  config.add_name('сельский округ', 'с/о.')
  config.add_name('сельское поселение', 'с/п.')
  config.add_name('сельсовет', 'с/с.')
  config.add_name('аал', 'аал')
  config.add_name('автодорога', 'автодорога')
  config.add_name('арбан', 'арбан')
  config.add_name('аул', 'аул')
  config.add_name('выселки(ок)', 'высел')
  config.add_name('городок', 'городок')
  config.add_name('деревня', 'д.', %w(дер))
  config.add_name('железнодорожная будка', 'ж/д_будка')
  config.add_name('железнодорожная казарма', 'ж/д_казарм')
  config.add_name('ж/д останов. (обгонный) пункт', 'ж/д_оп')
  config.add_name('железнодорожная платформа', 'ж/д_платф')
  config.add_name('железнодорожный пост', 'ж/д_пост')
  config.add_name('железнодорожный разъезд', 'ж/д_рзд')
  config.add_name('железнодорожная станция', 'ж/д_ст', ['ж/д ст'])
  config.add_name('жилая зона', 'жилзона')
  config.add_name('жилой район', 'жилрайон')
  config.add_name('заимка', 'заимка')
  config.add_name('казарма', 'казарма')
  config.add_name('квартал', 'кв-л', ['кварт'])
  config.add_name('кордон', 'кордон')
  config.add_name('леспромхоз', 'лпх.')
  config.add_name('местечко', 'м.')
  config.add_name('микрорайон', 'мкр.', %w(мкрн микр))
  config.add_name('населенный пункт', 'нп')
  config.add_name('остров', 'остров')
  config.add_name('планировочный район', 'п/р')
  config.add_name('поселок и(при) станция(и)', 'п/ст')
  config.add_name('погост', 'погост')
  config.add_name('починок', 'починок')
  config.add_name('промышленная зона', 'промзона')
  config.add_name('разъезд', 'рзд')
  config.add_name('село', 'с.')
  config.add_name('слобода', 'сл.')
  config.add_name('садовое неком-е товарищество', 'садовое товарищество', ['снт','СНТ','садоводство'])
  config.add_name('станция', 'ст-я')
  config.add_name('станица', 'ст-ца', %w(стн ст))
  config.add_name('хутор', 'х.')
  config.add_name('абонентский ящик', 'а/я')
  config.add_name('аллея', 'аллея')
  config.add_name('берег', 'берег')
  config.add_name('бульвар', 'б-р', %w(бул бульв))
  config.add_name('бугор', 'бугор')
  config.add_name('вал', 'вал')
  config.add_name('въезд', 'въезд')
#  config.add_name('гаражно-строительный кооператив', 'гск.')
  config.add_name('дорога', 'дор.')
  config.add_name('животноводческая точка', 'жт.')
  config.add_name('заезд', 'заезд')
  config.add_name('зона', 'зона')
  config.add_name('канал', 'канал', ['кан'])
  config.add_name('километр', 'км.')
  config.add_name('кольцо', 'кольцо')
  config.add_name('коса', 'коса')
  config.add_name('линия', 'линия', ['лин'])
  config.add_name('мост', 'мост')
  config.add_name('набережная', 'наб.')
  config.add_name('парк', 'парк')
  config.add_name('переулок', 'пер.', ['пер-к'])
  config.add_name('переезд', 'переезд')
  config.add_name('площадь', 'пл.')
  config.add_name('платформа', 'платф.')
  config.add_name('площадка', 'пл-ка')
  config.add_name('полустанок', 'полустанок')
  config.add_name('проспект', 'пр-кт', ['пр', 'просп', 'пр-т'])
  config.add_name('проезд', 'проезд', ['пр-д', 'прз', 'прд'])
  config.add_name('просек', 'просек')
  config.add_name('просека', 'просека')
  config.add_name('проселок', 'проселок')
  config.add_name('проток', 'проток')
  config.add_name('протока', 'протока')
  config.add_name('проулок', 'проулок')
  config.add_name('ряды', 'ряды')
  config.add_name('сад', 'сад')
  config.add_name('сквер', 'сквер')
  config.add_name('спуск', 'спуск')
  config.add_name('строение', 'стр')
  config.add_name('тоннель', 'тоннель')
  config.add_name('тракт', 'тр.')
  config.add_name('тупик', 'туп.')
  config.add_name('улица', 'ул.')
  config.add_name('участок', 'уч-к')
  config.add_name('ферма', 'ферма')
  config.add_name('шоссе', 'ш.', ['шос'])
  config.add_name('эстакада', 'эстакада')
  config.add_name('дачное некоммерческое партнерство', 'днп')
  config.add_name('некоммерческое партнерство', 'н/п.')
  config.add_name('фермерское хозяйство', 'ф/х')
  config.add_name('коттеджный поселок', 'кп.', ['коттеджный'])
  config.add_name('Город федерального значения', 'г.ф.з.',['гфз', 'ГФЗ'])
  config.add_name('Внутригородская территория', 'вн.тер. г.')
  config.add_name('Городской округ', 'г.о.',['го'])
  config.add_name('Муниципальный район', 'м.р-н.')
  config.add_name('Поселение', 'пос.')
  config.add_name('Сельское муницип.образование', 'с/мо')
  config.add_name('городской поселок', 'гп.')
  config.add_name('Железнодорожная будка', 'ж/д б-ка')
  config.add_name('Аллея', 'ал.')
  config.add_name('Балка', 'балка')
  config.add_name('Бухта', 'бухта')
  config.add_name('Взвоз', 'взв.')
  config.add_name('Гаражно-строительный кооператив', 'гск.',['Гаражно-строит-ный кооператив', 'Гаражно-строительный кооп.','Гаражно-строительный кооп'])
  config.add_name('Дачное неком-е партнерство', 'днп')
  config.add_name('Заезд', 'ззд.')
  config.add_name('Кольцо', 'к-цо')
  config.add_name('Линия', 'лн.')
  config.add_name('Маяк', 'маяк')
  config.add_name('Магистраль', 'мгстр.')
  config.add_name('Местность', 'местность', ['м-ть'])
  config.add_name('Переезд', 'пер-д',['прзд'])
  config.add_name('Просек', 'пр-к')
  config.add_name('Просека', 'пр-ка')
  config.add_name('Проселок', 'пр-лок')
  config.add_name('Проулок', 'проул.')
  config.add_name('Разъезд', 'рзд.')
  config.add_name('Ряд(ы)', 'ряд')
  config.add_name('Съезд', 'сзд.')
  config.add_name('Спуск', 'с-к.')
  config.add_name('Сквер', 'с-р.')
  config.add_name('Фермерское хозяйство', 'ф/х.')
  config.add_name('Владение', 'влд.')
  config.add_name('Дом', 'д.')
  config.add_name('Домовладение', 'двлд.')
  config.add_name('Здание', 'зд.',['з.','з'])
  config.add_name('Корпус', 'к.',['корп'])
  config.add_name('Котельная', 'кот.')
  config.add_name('Объект незав. строительства', 'ОНС')
  config.add_name('Павильон', 'пав.')
  config.add_name('Сооружение', 'соор.')
  config.add_name('Строение', 'стр.')
  config.add_name('Гараж', 'г-ж.')
  config.add_name('Квартира', 'кв.')
  config.add_name('Комната', 'ком.')
  config.add_name('Офис', 'офис')
  config.add_name('Погреб', 'п-б.')
  config.add_name('Подвал', 'подв.')
  config.add_name('Помещение', 'помещ.')
  config.add_name('Рабочий участок', 'раб.уч.')
  config.add_name('Склад', 'скл.')
  config.add_name('Торговый зал', 'торг. зал')
  config.add_name('Цех', 'цех')
  config.add_name('Внутригородской район', 'вн.р-н')
  config.add_name('Городское поселение', 'г. п.')
  config.add_name('Сельское поселение', 'с.п.')
  config.add_name('Берег', 'б-г')
  config.add_name('Въезд', 'взд.')
  config.add_name('Городок', 'г-к')
  config.add_name('Гаражно-строительный кооператив', 'гск.')
  config.add_name('Железнодорожная казарма', 'ж/д к-ма')
  config.add_name('Железнодорожная платформа', 'ж/д пл-ма')
  config.add_name('Железнодорожный разъезд', 'ж/д рзд.')
  config.add_name('Железнодорожная станция', 'ж/д ст.')
  config.add_name('Жилой район', 'ж/р')
  config.add_name('Зона (массив)', 'зона')
  config.add_name('Месторождение', 'месторожд.')
  config.add_name('Местечко', 'м-ко')
  config.add_name('Остров', 'ост-в')
  config.add_name('Промышленный район', 'п/р',['пром р-н'])
  config.add_name('Починок', 'п-к')
  config.add_name('Порт', 'порт')
  config.add_name('Станция', 'ст.')
  config.add_name('Территория ГСК', 'тер. ГСК.',['тер ГСК'])
  config.add_name('Территория ДНО', 'тер. ДНО.',['тер ДНО'])
  config.add_name('Территория ДНП', 'тер. ДНП.',['тер ДНП'])
  config.add_name('Территория ДНТ', 'тер. ДНТ.',['тер ДНТ'])
  config.add_name('Территория ДПК', 'тер. ДПК.',['тер ДПК'])
  config.add_name('Территория ОНО', 'тер. ОНО.',['тер ОНО'])
  config.add_name('Территория ОНП', 'тер. ОНП.',['тер ОНП'])
  config.add_name('Территория ОНТ', 'тер. ОНТ.',['тер ОНТ'])
  config.add_name('Территория ОПК', 'тер. ОПК.',['тер ОПК'])
  config.add_name('Территория СНО', 'тер. СНО.',['тер СНО'])
  config.add_name('Территория СНП', 'тер. СНП.',['тер СНП'])
  config.add_name('Территория СНТ', 'тер. СНТ.',['тер СНТ'])
  config.add_name('Территория СПК', 'тер. СПК.',['тер СПК'])
  config.add_name('Территория ТСН', 'тер. ТСН.',['тер ТСН'])
  config.add_name('Территория ФХ', 'тер.ф.х.',['тер фх','тер.фх.'])
  config.add_name('Усадьба', 'ус.')
  config.add_name('Юрты', 'ю.')
  config.add_name('Земельный участок', 'з/у')

  config.add_exception(
    'Чувашская Республика - Чувашия', 'Чувашия'
  )

  config.add_exception(
    'Ханты-Мансийский Автономный округ - Югра',
    'Ханты-Мансийский Автономный округ - Югра'
  )

  config.add_replacement(
      'Чувашская Республика -', ['Чувашская Респ.', 'Чувашская Республика']
  )

  proper_names =
    File.readlines(File.join(File.dirname(__FILE__), '../config/names.txt'))

  proper_names.map(&:strip).each do |name|
    config.add_proper_name(name)
  end

  synonyms =
    YAML.load_file(File.join(File.dirname(__FILE__), '../config/synonyms.yml'))

  synonyms.each do |synonym|
    config.add_synonym(*synonym)
  end
end
