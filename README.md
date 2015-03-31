# FIAS

[![Build Status](https://travis-ci.org/evilmartians/fias.svg)](http://travis-ci.org/evilmartians/fias)
[![Code Climate](https://codeclimate.com/github/evilmartians/fias/badges/gpa.svg)](https://codeclimate.com/github/evilmartians/fias)
[![Test Coverage](https://codeclimate.com/github/evilmartians/fias/badges/coverage.svg)](https://codeclimate.com/github/evilmartians/fias)

Ruby wrapper for the Russian [ФИАС](http://fias.nalog.ru) database.

Designed for usage with Ruby on Rails and a PostgreSQL backend.

<a href="https://evilmartians.com/?utm_source=fias-gem">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54">
</a>

Think twice before you decide to use a standalone copy of FIAS database in your project. [КЛАДР в облаке](https://kladr-api.ru/) could also be a solution.

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'fias'
```

And then execute:

    $ bundle

Or install it yourself:

    $ gem install fias

## Import into PostgreSQL

    $ mkdir -p tmp/fias && cd tmp/fias
    $ bundle exec rake fias:download | xargs wget
    $ unrar e fias_dbf.rar
    $ bundle exec rake fias:create_tables fias:import DATABASE_URL=postgres://localhost/fias

The rake task accepts options through ENV variables:

* `TABLES` to specify a comma-separated list of tables to import or create. See `Fias::Import::Dbf::TABLES` for the list of key names. Use `houses` as an alias for HOUSE* tables and `nordocs` for NORDOC* tables. In most cases you'll need only the  `address_objects` table.
* `PREFIX` for database tables prefix ('fias_' by default).
* `PATH` to specify DBF files location ('tmp/fias' by default).
* `DATABASE_URL` to set database credentials (required explicitly even with a Ruby on Rails project).

This gem uses `COPY FROM STDIN BINARY` to import data. At the moment it works with PostgreSQL only.

## Notes about FIAS

1. FIAS address objects table contains a lot of fields which are useless in most cases (tax office ID, legal document ID, etc.).
2. Address objects table contains a lot of historical records (more than 50%, in fact), which are useless in most cases.
3. Every record in the address object table could have multiple parents. For example, "Nevsky prospekt" in Saint Petersburg has two parents: Saint Petersburg (active) and Leningrad (historical name of the city, inactive). Most hierarchy libraries do accept just one parent for a record.
4. Using UUID type field as a primary key as it used in FIAS is not a good idea if you want to use `ancestry` or `closure_tree` gems to navigate through record tree.
5. Typical SQL production server settings are optimized for reading, so the import process in production environment could take a dramatically long time.

## Notes on initial import workflow

1. Use raw FIAS tables just as a temporary data source for creating/updating primary address objects table for your application.
2. The only requirement is to keep AOGUID, PARENTGUID and AOID fields in target table. You will need them for updating.
3. Keep your addressing object table immutable. This will give you an ability to work with huge amounts of addressing data locally. Send the result to production environment via a SQL dump.
4. FIAS contains some duplicates. Duplicates are records which have different UUIDs but equal names, abbrevations and nesting level. It is up to you to decide on how to deal with it: completely remove them or just mark as hidden. Krasnodar city has a lot of equally named streets situated in different districts.
5. [closure_tree](https://github.com/mceachen/closure_tree) works great as a hierarchy backend. Use [pg_closure_tree_rebuild](https://github.com/gzigzigzeo/pg_closure_tree_rebuild) to rebuild the hierarchy table from scratch.

[See example](examples/create.rb).

## Toponyms

Every FIAS address object has two fields: `formalname`, which holds the toponym (the name of a geographical object) and `shortname`, which holds its type (street, city, etc.). FIAS contains the list of all available `shortname` values and their corresponding long forms in the `address_object_types` table (SOCRBASE.DBF).

### Canonical forms

In real life people use a lot of type name variations. For example, 'проспект' can be written as 'пр' or 'пр-кт'.

You can convert any variation to a canonical form:

```ruby
Fias::Name::Canonical.canonical('поселок')
# => [
#  'поселок', # FIAS canonical full name
#  'п',       # FIAS canonical short name (as in address_objects table)
#  'п.',      # Short name with dot if needed
#  'пос',     # Alias
#  'посёлок'  # Alias
# ]
```

See [fias.rb](lib/fias.rb) for a list of settings.

### Append type to toponym

Use `Fias::Name::Append` to build toponym names in conformity with the rules of grammar:

```ruby
Fias::Name::Append.append('Санкт-Петербург', 'г')
# => ['г. Санкт-Петербург', 'город Санкт-Петербург']

Fias::Name::Append.append('Невский', 'пр')
# => ['Невский пр-кт', 'Невский проспект']

Fias::Name::Append.append('Чечня', 'республика')
# => ['Респ. Чечня', 'Республика Чечня']

Fias::Name::Append.append('Чеченская', 'республика')
# => ['Чеченская Респ.', 'Чеченская Республика']
```

You can pass any form of type name: full, short, an alias, with or without the dot.

### Extract a toponym

Sometimes you need to extract a toponym and its type from a plain string:

```ruby
Fias::Name::Extract.extract('Город Санкт-Петербург')
# => ['Санкт-Петербург', 'город', 'г', 'г.']

Fias::Name::Extract.extract('ул. Казачий Вал')
# => ['Казачий Вал', 'улица', 'ул', 'ул.']
```

### Extract house number

Sometimes street names come mixed up with house numbers, and you need to extract the house number from a string to clean it up for indexing:

```ruby
Fias::Name::HouseNumber.extract('Ново-Садовая ул,303а')
# => ['Ново-Садовая ул', '303а']

Fias::Name::HouseNumber.extract('пр.Энергетиков 72/2')
# => ['пр.Энергетиков', '72/2']
```

## Searching

Given you have a set of structured addresses:

```ruby
[
  { region: 'Еврейская АОбл', city: 'г. Биробиджан', street: 'Шолом-Алейхема' },
  { city: 'Санкт-Петербург', street: 'Лермонтовский проспект' }
]
```

You need to find a FIAS item for each address in set.

Your project may use a full-text search engine (Sphinx, ElasticSearch) or just a SQL database. Search principles are the same, but the implementation would differ. This library contains helpful modules and base classes to facilitate searching.

### Indexing

Each toponym consists of words; some of them are considered "special". Said "special" words could have synonyms or different forms, they could be skipped by user or could be written differently in FIAS database itself.

Examples:

* "50 лет Октября" == "50-летия Октября"
* "1-ая Советская" == "1 Советская" || "Советская 1-я"
* "Большой Проспект П.С." == "Большой Проспект Петроградской"
* "имени Максима Горького" == "им. Горького" || "Горького"
* "ул. Цюрупы" == "Цурюпы" || "Цюрупа" || "Цорюпы" || "Цорупа" (that's my favorite!)

You should trait them as equal when performing search.

Note that we are talking about toponym names with types extracted (see type extraction above).

#### Splitting the words

Words are split according to a set of simple rules aimed to simplify disclosure of synonyms and determination of optional parts.

```ruby
Addressing::Name::Split.split("50 лет Октября")
# => ["50 лет", "октября"]

Addressing::Name::Split.split("Ю.Р.Г.Эрвье")
# => ["ю.р.г.", "эрвье"]
```

#### Finding synonyms and optional words

Given we have a street named `им. академика И.П.Павлова` in FIAS, most people will reference it as just `Павлова` street, some will write it as `имени Павлова`, and some - `академика Павлова`. Basically, nobody except the FIAS database would reference it by the exact original name.

```ruby
Addressing::Name::Synonyms.expand('им. академика И.П.Павлова')

# => [["им", "имени", "им.", ""],
# ["ак.", "академика", ""],
# ["и.п.", ""],
# ["павлова"]]
```

Will return all possible forms for each word. Empty strings here mark optional words.

```ruby
Addressing::Name::Synonyms.tokens('им. академика И.П.Павлова')

# => ["им", "имени", "им.", "ак.", "академика", "и.п.", "павлова"]
```

Will return array with all possible words.

You can also calculate all possible name combinations:

```ruby
Addressing::Name::Synonyms.forms('им. И.П.Павлова')
# => [
#   'и.п. им павлова',
#   'им павлова',
#   'и.п. имени павлова',
#   'имени павлова',
#   'и.п. им. павлова',
#   'им. павлова',
#   'и.п. павлова',
#   'павлова'
# ]
```

#### Generating search index

In search index you need:
* name tokens (result of `Fias::Name::Synonyms.tokens`)
* name forms (result of `Fias::Name::Synonyms.forms`)
* ancestor ids

See [indexing example](examples/generate_index.rb).

### Querying

Performing a search will execute these three steps:

1. Preparation: sanitizing request values, splitting toponym name and type, etc.
2. Querying: finding possible candidates in addressing object tree.
3. Decision: determining the most suitable result depending on similarity with request.

#### Defining in-app query class

```ruby
class Query
  include Fias::Query

  def find(tokens)
    return [] if tokens.blank? # Empty array has no type, Sequel fails.

    op = Sequel.pg_array_op(:tokens)

    DB[:address_objects]
      .select(:id, :name, :abbr, :parent_id, :ancestry, :forms, :tokens)
      .where(op.overlaps(tokens))
      .to_a
  end
end
```

`#find` accepts splitted object name (`Fias::Name::Split.split` result). It must search all address objects overlapping their tokens with given. It must return array of hashes with keys you see above.

* `:abbr` - FIAS shortname value.
* `:ancestry` - array of ancestor ids.
* `:forms` - object name forms (`Fias::Name::Synonyms.forms`)
* `:tokens` - object name tokens (`Fias::Name::Synonyms.tokens`)

See [indexing example](examples/generate_index.rb).

#### Query params

```ruby
query = Query.new(
  region: 'Еврейская АОбл', city: 'г. Биробиджан', street: 'Шолом-Алейхема'
)

query.params.sanitized
# => {
#   :region => ["Еврейская", "автономная область", "Аобл", "Аобл"],
#   :city   => ["Биробиджан", "город", "г", "г."],
#   :street => ["Шолом-Алейхема"]
# }
```

Allowed params are: `%i(region district city subcity street)`

#### Result

```ruby
query.perform
#
# [[13213, {:id=>72344, :name=>"Шолом-Алейхема", :abbr=>"ул", :parent_id=>184027, :ancestry=>[184027, 12550], :forms=>["шолом-
# алейхема"], :tokens=>["шолом-алейхема"], :key=>:street}]]
```

Result is array.

* Each element of array contains two values: factor of equality and found object.
* If there are more then one row in array it means that query results are ambigous. All elements will have same factors.
* Nothing found if empty.

## Contributors

* Victor Sokolov (@gzigzigzeo)
* Vlad Bokov (@razum2um)

Special thanks to @gazay.

## Contributing

1. Fork it ( https://github.com/evilmartians/fias/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The MIT License
