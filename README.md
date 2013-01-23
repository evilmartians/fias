# Федеральная Информационная Адресная Система (ФИАС)

Для работы с базой потребуются файлы полной БД ФИАС в формате DBF. Скачать их можно по адресу:

    http://fias.nalog.ru/Public/DownloadPage.aspx

Там же можно скачать описание структуры базы.

# Установка и подготовка базы

1. Подключить гем

```
gem 'fias', git: 'https://github.com/evilmartians/kladr.git'
```

2. Скачать и распаковать базу ФИАС в tmp/fias (по умолчанию)

# Импорт структуры данных

Возможны два варианта:

```
rake fias:create_tables [DATABASE_URL=... PREFIX=... PATH=... ONLY=...]
```

Либо:

```
rails g fias:migration [--path=... --prefix=... --only=...]
```

Первый вариант - для использования гема вне рельсов, либо для случая, когда
актуальная база ФИАС будет использоваться только для локального мапинга, и
на продакшн попасть не должна.

В параметре only можно передать имена нужных таблиц, houses - все
таблицы домов.

# Импорт данных

```
rake fias:import PREFIX=fias PATH=tmp/fias ONLY=address_objects
rake fias:import PREFIX=fias PATH=tmp/fias ONLY=houses
```

Первый пример импортирует только адресные объекты (без справочников),
второй - только дома.

Поддерживается импорт в Postgres и SQLite (нужно для :memory: баз)

# Импорт данных в память (для рейк тасок)

```ruby
ActiveRecord::Base.configurations['fias'] = {
  :adapter  => 'sqlite3',
  :database => ':memory:'
}
Fias::AddressObject.establish_connection :fias

fias = Fias::DbfWrapper.new('tmp/fias')
importer = Fias::Importer.build(
  adapter: 'sqlite3', connection: Fias::AddressObject.connection.raw_connection
)
tables = fias.tables(:address_objects)

# Мигрейт. В таком виде так как стандартный мигратор всегда открывает новое
# соединение с БД, а в случае с SQLite это означает пересоздание базы :memory:.
Fias::AddressObject.connection.instance_exec do
  eval(importer.schema(tables))
end

importer.import(tables) do |name, record, index|
  record[:aclevel] == 1 # Только активные
end

Fias::AddressObject.count # И дальше импорт
```

# Некоторые замечания про ФИАС

1. ФИАС хранит историю изменений информации адресных объектов. Например,
в ней есть и Ленинград и Санкт-Петербург. Исторические версии это
двунаправленный список.
2. Записи базы данных ФИАС имеют признак актуальности.
3. Ленинград и Санкт-Петербург, хотя, и хранятся в разных записях базы данных,
являются одним и тем же территориальным образованием. Код территориального
образования хранится в поле AOGUID. Из внешних таблиц логично ссылаться
на AOGUID, а не на AOID.

# Маппинг, он же итерирование

Задачи:
1. Сопоставить записи базы приложения и базы
ФИАС.
2. Уведомлять приложение об изменениях в связанных
объектах ФИАСа.
3. Уведомлять приложения о новых
данных в ФИАСе.

В таблице, с которой устанавливаются соответствия нужно создать поле для
хранения UUID записи ФИАСа.

На примере регионов:

```ruby
# Будем искать соответствия регионов сайта регионам в ФИАС
scope = Region
fias_scope = Fias::AddressObject.leveled(:region)

# Обработчик событий итератора
matcher = ->(action, record, *objects) {
  match = objects.first

  case action

  # Появилась новая запись в ФИАСе
  when :created
    puts "Region #{match.abbrevated}"
    Region.create!(
      fias_reference: match.id,
      title: match.abbrevated
    )

  # Элемент в ФИАСе обновлен, нужно (?) обновить базу приложения
  when :updated
    record.update_attributes(
      title: match.abbrevated,
      fias_reference: match.id
    )
    puts "#{record.title} became #{match.abbrevated}"

  # Объект в ФИАСе был, но из актуального состояния перешел в неактуальное.
  # Типа, Припять: умерший город.
  # Скорее всего, такой элемент в базе приложения нужно скрыть.
  when :deleted
    raise NotImplementedError, "#{record.title} #{objects.first.abbrevated}"

  # Элемент в ФИАСе разделился: например, поселение Черто-Полохово
  # было преобразовано в две деревни: Чертово и Полохово
  # В этом случае objects это новые версии объекта.
  when :split
    raise NotImplementedError

  # Элемент в ФИАСе объединился
  # Типа, присоединили Московскую область к Москве
  # В этом случае objects.first это запись ФИАС о новом объекте, а остальные
  # элементы objects - записи ФИАС объединившихся объектов.
  when :joined
    raise NotImplementedError

  # Элементу базы приложения нет соответствия в ФИАСе пытаемся сопоставить
  # Вообще говоря, лучше новые соответствия модерировать.
  when :match
    match = objects.detect { |b| b.actual? || b.name == record.title }
    if match.present?
      record.update_attributes(
        title: match.abbrevated,
        fias_reference: match.id
      )
      puts "#{record.title} became #{match.abbrevated} (new)"
    else
      puts "Record not found #{record.title}"
    end

  else
    raise 'Unknown action!'
  end
}

# Итерирует существующие в базе приложения элементы
#   fias_reference - название колонки с UUID соответствующей региону записи
#   ФИАСа
#   title - название региона
fias_scope.match_existing(scope, :fias_reference, :title, &matcher)

# Итерирует отсутствующие в базе приложения, но имеющиеся в скоупе
# ФИАСа адреса.
fias_scope.actual.match_missing(scope, :fias_reference, &matcher)
```

Примечания:
1. В случае неоднозначного совпадения ФИАС и приложения, можно ставить поиск
соответствия на модерацию.
2. В случае :split, :joined - так же. Хотя, разделения происходят и нечасто,
однако, в ФИАСе таких случаев больше полутора тысяч, лучше учесть.
3. При начальном импорте данных из ФИАСа, #match_missing лучше начать вызывать
только после того как соответствия старой базы ФИАСу будут полностью разрулены.

# Работа с данными

Существующие регионы:

```ruby
Fias::AddressObject.actual.leveled(:region).all
```

Подчиненные объекты в регионе (области, районы, столица региона):

```ruby
region = Fias::AddressObject.actual.leveled(:region).first
region.children.actual
```

# TODO

1. Индексы.

# Полезные ссылки

* http://fias.nalog.ru/Public/DownloadPage.aspx
* http://wiki.gis-lab.info/w/%D0%A4%D0%98%D0%90%D0%A1#.D0.A2.D0.B5.D0.BA.D1.81.D1.82.D0.BE.D0.B2.D1.8B.D0.B5_.D1.8D.D0.BB.D0.B5.D0.BC.D0.B5.D0.BD.D1.82.D1.8B_.D0.B0.D0.B4.D1.80.D0.B5.D1.81.D0.B0
* http://basicdata.ru
