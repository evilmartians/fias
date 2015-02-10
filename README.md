# Fias

Ruby wrapper for the Russian [ФИАС](http://fias.nalog.ru) database.

Works best with Ruby on Rails and PostgreSQL backend.

## Import into SQL

    $ mkdir tmp/fias && cd tmp/fias
    $ bundle exec rake fias:download | xargs wget
    $ unrar e fias_dbf.rar
    $ bundle exec rake environment fias:create_tables fias:import

## Notes

The rake task accepts options through ENV vars:

* `TABLES` to specify a comma-separated list of a tables to import/create. See `Fias::Import::Dbf::TABLES` for the list of key names. Use `houses` as an alias for HOUSE* tables. In most cases you'll need `address_objects` table only.
* `PREFIX` for the database tables prefix ('fias_' by default).
* `PATH` to specify DBF files location ('tmp/fias' by default).

Gem uses `COPY FROM STDIN BINARY` to import data. Works with PostgreSQL only.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fias'
```

And then execute:

    $ bundle

Or install it yourself:

    $ gem install fias

## Contributing

1. Fork it ( https://github.com/evilmartians/fias/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
