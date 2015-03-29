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
require 'fias/railtie' if defined?(Rails)

Fias.configure do |config|
  config.add_name('автономный округ', 'АО')
  config.add_name('автономная область', 'Аобл')
  config.add_name('город', 'г.')
  config.add_name('край', 'край')
  config.add_name('область', 'обл.')
  config.add_name('округ', 'округ')
  config.add_name('республика', 'Респ.')
  config.add_name('поселение', 'п.')
  config.add_name('район', 'р-н')
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
  config.add_name('сельская администрация', 'с/а')
  config.add_name('сельское муниципальное образо', 'с/мо')
  config.add_name('сельский округ', 'с/о')
  config.add_name('сельское поселение', 'с/п')
  config.add_name('сельсовет', 'с/с')
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
  config.add_name('леспромхоз', 'лпх')
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
  config.add_name('садовое неком-е товарищество', 'снт', ['садоводство'])
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
  config.add_name('гаражно-строительный кооператив', 'гск')
  config.add_name('дорога', 'дор.')
  config.add_name('животноводческая точка', 'жт')
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
  config.add_name('гаражно-строительный кооператив', 'гск')
  config.add_name('дачное некоммерческое партнерство', 'днп')
  config.add_name('некоммерческое партнерство', 'н/п')
  config.add_name('садовое товарищество', 'снт')
  config.add_name('фермерское хозяйство', 'ф/х')
  config.add_name('коттеджный поселок', 'кп', ['коттеджный'])

  config.add_exception(
    'Чувашская Республика - Чувашия', 'Чувашия'
  )
  config.add_exception(
    'Ханты-Мансийский Автономный округ - Югра',
    'Ханты-Мансийский Автономный округ - Югра'
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
