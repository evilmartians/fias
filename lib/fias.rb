require 'unicode'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/slice'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/array/extract_options'
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
require 'fias/name/short'
require 'fias/name/long'
require 'fias/railtie' if defined?(Rails)

module Fias
  class << self
    attr_reader :config

    def configure(&block)
      @config = Config.new(&block)
    end
  end
end

Fias.configure do |config|
  config.canonical('автономный округ', 'АО', dot: false)
  config.canonical('автономная область', 'Аобл', dot: false)
  config.canonical('город', 'г')
  config.canonical('край', 'край', dot: false)
  config.canonical('область', 'обл')
  config.canonical('округ', 'округ', dot: false)
  config.canonical('республика', 'Респ')
  config.canonical('поселение', 'п')
  config.canonical('район', 'р-н', dot: false)
  config.canonical('территория', 'тер')
  config.canonical('улус', 'у')
  config.canonical('волость', 'волость', dot: false)
  config.canonical('дачный поселок', 'дп', dot: false)
  config.canonical('курортный поселок', 'кп', dot: false)
  config.canonical('массив', 'массив', dot: false)
  config.canonical('поселок', 'п', aliases: %w(пос посёлок))
  config.canonical('почтовое отделение', 'п/о', dot: false)
  config.canonical('поселок городского типа', 'пгт', dot: false)
  config.canonical('рабочий поселок', 'рп', dot: false)
  config.canonical('сельская администрация', 'с/а', dot: false)
  config.canonical('сельское муниципальное образо', 'с/мо', dot: false)
  config.canonical('сельский округ', 'с/о', dot: false)
  config.canonical('сельское поселение', 'с/п', dot: false)
  config.canonical('сельсовет', 'с/с', dot: false)
  config.canonical('аал', 'аал', dot: false)
  config.canonical('автодорога', 'автодорога', dot: false)
  config.canonical('арбан', 'арбан', dot: false)
  config.canonical('аул', 'аул', dot: false)
  config.canonical('выселки(ок)', 'высел')
  config.canonical('городок', 'городок', dot: false)
  config.canonical('деревня', 'д')
  config.canonical('железнодорожная будка', 'ж/д_будка', dot: false)
  config.canonical('железнодорожная казарма', 'ж/д_казарм', dot: false)
  config.canonical('ж/д останов. (обгонный) пункт', 'ж/д_оп', dot: false)
  config.canonical('железнодорожная платформа', 'ж/д_платф', dot: false)
  config.canonical('железнодорожный пост', 'ж/д_пост', dot: false)
  config.canonical('железнодорожный разъезд', 'ж/д_рзд', dot: false)
  config.canonical(
    'железнодорожная станция', 'ж/д_ст', aliases: ['ж/д ст'], dot: false
  )
  config.canonical('жилая зона', 'жилзона', dot: false)
  config.canonical('жилой район', 'жилрайон', dot: false)
  config.canonical('заимка', 'заимка', dot: false)
  config.canonical('казарма', 'казарма', dot: false)
  config.canonical('квартал', 'кв-л', aliases: ['кварт'], dot: false)
  config.canonical('кордон', 'кордон', dot: false)
  config.canonical('леспромхоз', 'лпх', dot: false)
  config.canonical('местечко', 'м')
  config.canonical(
    'микрорайон', 'мкр', aliases: %w(мкрн микр), dot: false
  )
  config.canonical('населенный пункт', 'нп', dot: false)
  config.canonical('остров', 'остров', dot: false)
  config.canonical('планировочный район', 'п/р', dot: false)
  config.canonical('поселок и(при) станция(и)', 'п/ст', dot: false)
  config.canonical('погост', 'погост', dot: false)
  config.canonical('починок', 'починок', dot: false)
  config.canonical('промышленная зона', 'промзона', dot: false)
  config.canonical('разъезд', 'рзд', dot: false)
  config.canonical('село', 'с')
  config.canonical('слобода', 'сл')
  config.canonical(
    'садовое неком-е товарищество',
    'снт',
    aliases: ['садоводство'],
    dot: false
  )
  config.canonical('станция', 'ст-я', dot: false)
  config.canonical('станица', 'ст-ца', aliases: %w(стн ст), dot: false)
  config.canonical('хутор', 'х')
  config.canonical('абонентский ящик', 'а/я', dot: false)
  config.canonical('аллея', 'аллея', dot: false)
  config.canonical('берег', 'берег', dot: false)
  config.canonical('бульвар', 'б-р', aliases: %w(бул бульв), dot: false)
  config.canonical('бугор', 'бугор', dot: false)
  config.canonical('вал', 'вал', dot: false)
  config.canonical('въезд', 'въезд', dot: false)
  config.canonical('гаражно-строительный кооперат', 'гск', dot: false)
  config.canonical('дорога', 'дор')
  config.canonical('животноводческая точка', 'жт')
  config.canonical('заезд', 'заезд', dot: false)
  config.canonical('зона', 'зона', dot: false)
  config.canonical('канал', 'канал', aliases: ['кан'], dot: false)
  config.canonical('километр', 'км')
  config.canonical('кольцо', 'кольцо', dot: false)
  config.canonical('коса', 'коса', dot: false)
  config.canonical('линия', 'линия', aliases: ['лин'], dot: false)
  config.canonical('мост', 'мост', dot: false)
  config.canonical('набережная', 'наб')
  config.canonical('парк', 'парк', dot: false)
  config.canonical('переулок', 'пер', aliases: ['пер-к'])
  config.canonical('переезд', 'переезд', dot: false)
  config.canonical('площадь', 'пл')
  config.canonical('платформа', 'платф')
  config.canonical('площадка', 'пл-ка', dot: false)
  config.canonical('полустанок', 'полустанок', dot: false)
  config.canonical(
    'проспект', 'пр-кт', aliases: ['пр', 'просп', 'пр-т'], dot: false
  )
  config.canonical(
    'проезд', 'проезд', aliases: ['пр-д', 'прз', 'прд'], dot: false
  )
  config.canonical('просек', 'просек', dot: false)
  config.canonical('просека', 'просека', dot: false)
  config.canonical('проселок', 'проселок', dot: false)
  config.canonical('проток', 'проток', dot: false)
  config.canonical('протока', 'протока', dot: false)
  config.canonical('проулок', 'проулок', dot: false)
  config.canonical('ряды', 'ряды', dot: false)
  config.canonical('сад', 'сад', dot: false)
  config.canonical('сквер', 'сквер', dot: false)
  config.canonical('спуск', 'спуск', dot: false)
  config.canonical('строение', 'стр')
  config.canonical('тоннель', 'тоннель', dot: false)
  config.canonical('тракт', 'тр')
  config.canonical('тупик', 'туп')
  config.canonical('улица', 'ул')
  config.canonical('участок', 'уч-к', dot: false)
  config.canonical('ферма', 'ферма', dot: false)
  config.canonical('шоссе', 'ш', aliases: ['шос'])
  config.canonical('эстакада', 'эстакада', dot: false)
  config.canonical('гаражно-строительный кооператив', 'гск', dot: false)
  config.canonical('дачное некоммерческое партнерство', 'днп', dot: false)
  config.canonical('некоммерческое партнерство', 'н/п', dot: false)
  config.canonical('садовое товарищество', 'снт', dot: false)
  config.canonical('фермерское хозяйство', 'ф/х')
  config.canonical('коттеджный поселок', 'кп', aliases: ['коттеджный'])

  config.exception_for_append(
    'Чувашская Республика - Чувашия', 'Чувашия'
  )
  config.exception_for_append(
    'Ханты-Мансийский Автономный округ - Югра',
    'Ханты-Мансийский Автономный округ - Югра'
  )
end
