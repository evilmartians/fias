# Fias

Work with [ФИАС](http://fias.nalog.ru) database from .DBF into PostgreSQL database.

## Import

    $ mkdir tmp/fias && cd tmp/fias
    $ bundle exec rake fias:download | xargs wget
    $ unrar e fias_dbf.rar
    $ bundle exec rake environment fias:create_tables fias:import

## Notes

Rake task accepts options through env vars:

* `TABLES` to specify comma-separated list of a tables to import/create. See `Fias::Import::Dbf::TABLES` for a key names. Use `houses` as an alias for HOUSE* tables. In most cases you need only `address_objects` table.
* `PREFIX` for a database tables prefix ('fias_' by default).
* `PATH` to specify DBF files location ('tmp/fias' by default).

Gem uses COPY FROM STDIN BINARY to import data.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fias-import'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fias-import

## Contributing

1. Fork it ( https://github.com/gzigzigzeo/fias-import/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
