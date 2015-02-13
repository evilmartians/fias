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
  config.canonical('автономный округ', 'АО')
  config.canonical('автономная область', 'Аобл')
  config.canonical('город', 'г.')
  config.canonical('край', 'край')
  config.canonical('область', 'обл.')
  config.canonical('округ', 'округ')
  config.canonical('республика', 'Респ.')
  config.canonical('поселение', 'п.')
  config.canonical('район', 'р-н')
  config.canonical('территория', 'тер.')
  config.canonical('улус', 'у.')
  config.canonical('волость', 'волость')
  config.canonical('дачный поселок', 'дп.')
  config.canonical('курортный поселок', 'кп.')
  config.canonical('массив', 'массив')
  config.canonical('поселок', 'п.', aliases: %w(пос посёлок))
  config.canonical('почтовое отделение', 'п/о')
  config.canonical('поселок городского типа', 'пгт')
  config.canonical('рабочий поселок', 'рп')
  config.canonical('сельская администрация', 'с/а')
  config.canonical('сельское муниципальное образо', 'с/мо')
  config.canonical('сельский округ', 'с/о')
  config.canonical('сельское поселение', 'с/п')
  config.canonical('сельсовет', 'с/с')
  config.canonical('аал', 'аал')
  config.canonical('автодорога', 'автодорога')
  config.canonical('арбан', 'арбан')
  config.canonical('аул', 'аул')
  config.canonical('выселки(ок)', 'высел')
  config.canonical('городок', 'городок')
  config.canonical('деревня', 'д.', aliases: %w(дер))
  config.canonical('железнодорожная будка', 'ж/д_будка')
  config.canonical('железнодорожная казарма', 'ж/д_казарм')
  config.canonical('ж/д останов. (обгонный) пункт', 'ж/д_оп')
  config.canonical('железнодорожная платформа', 'ж/д_платф')
  config.canonical('железнодорожный пост', 'ж/д_пост')
  config.canonical('железнодорожный разъезд', 'ж/д_рзд')
  config.canonical(
    'железнодорожная станция', 'ж/д_ст', aliases: ['ж/д ст']
  )
  config.canonical('жилая зона', 'жилзона')
  config.canonical('жилой район', 'жилрайон')
  config.canonical('заимка', 'заимка')
  config.canonical('казарма', 'казарма')
  config.canonical('квартал', 'кв-л', aliases: ['кварт'])
  config.canonical('кордон', 'кордон')
  config.canonical('леспромхоз', 'лпх')
  config.canonical('местечко', 'м.')
  config.canonical(
    'микрорайон', 'мкр.', aliases: %w(мкрн микр)
  )
  config.canonical('населенный пункт', 'нп')
  config.canonical('остров', 'остров')
  config.canonical('планировочный район', 'п/р')
  config.canonical('поселок и(при) станция(и)', 'п/ст')
  config.canonical('погост', 'погост')
  config.canonical('починок', 'починок')
  config.canonical('промышленная зона', 'промзона')
  config.canonical('разъезд', 'рзд')
  config.canonical('село', 'с.')
  config.canonical('слобода', 'сл.')
  config.canonical(
    'садовое неком-е товарищество',
    'снт',
    aliases: ['садоводство'],
    dot: false
  )
  config.canonical('станция', 'ст-я')
  config.canonical('станица', 'ст-ца', aliases: %w(стн ст))
  config.canonical('хутор', 'х.')
  config.canonical('абонентский ящик', 'а/я')
  config.canonical('аллея', 'аллея')
  config.canonical('берег', 'берег')
  config.canonical('бульвар', 'б-р', aliases: %w(бул бульв))
  config.canonical('бугор', 'бугор')
  config.canonical('вал', 'вал')
  config.canonical('въезд', 'въезд')
  config.canonical('гаражно-строительный кооперат', 'гск')
  config.canonical('дорога', 'дор.')
  config.canonical('животноводческая точка', 'жт')
  config.canonical('заезд', 'заезд')
  config.canonical('зона', 'зона')
  config.canonical('канал', 'канал', aliases: ['кан'])
  config.canonical('километр', 'км.')
  config.canonical('кольцо', 'кольцо')
  config.canonical('коса', 'коса')
  config.canonical('линия', 'линия', aliases: ['лин'])
  config.canonical('мост', 'мост')
  config.canonical('набережная', 'наб.')
  config.canonical('парк', 'парк')
  config.canonical('переулок', 'пер.', aliases: ['пер-к'])
  config.canonical('переезд', 'переезд')
  config.canonical('площадь', 'пл.')
  config.canonical('платформа', 'платф.')
  config.canonical('площадка', 'пл-ка')
  config.canonical('полустанок', 'полустанок')
  config.canonical(
    'проспект', 'пр-кт', aliases: ['пр', 'просп', 'пр-т']
  )
  config.canonical(
    'проезд', 'проезд', aliases: ['пр-д', 'прз', 'прд']
  )
  config.canonical('просек', 'просек')
  config.canonical('просека', 'просека')
  config.canonical('проселок', 'проселок')
  config.canonical('проток', 'проток')
  config.canonical('протока', 'протока')
  config.canonical('проулок', 'проулок')
  config.canonical('ряды', 'ряды')
  config.canonical('сад', 'сад')
  config.canonical('сквер', 'сквер')
  config.canonical('спуск', 'спуск')
  config.canonical('строение', 'стр')
  config.canonical('тоннель', 'тоннель')
  config.canonical('тракт', 'тр.')
  config.canonical('тупик', 'туп.')
  config.canonical('улица', 'ул.')
  config.canonical('участок', 'уч-к')
  config.canonical('ферма', 'ферма')
  config.canonical('шоссе', 'ш.', aliases: ['шос'])
  config.canonical('эстакада', 'эстакада')
  config.canonical('гаражно-строительный кооператив', 'гск')
  config.canonical('дачное некоммерческое партнерство', 'днп')
  config.canonical('некоммерческое партнерство', 'н/п')
  config.canonical('садовое товарищество', 'снт')
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
