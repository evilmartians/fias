require 'fias'
require 'fias/active_record/address_object'
require 'sqlite3'
require 'progress_bar'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
connection = ActiveRecord::Base.connection.raw_connection

wrapper = Fias::DbfWrapper.new('tmp/fias')
importer = Fias::Importer.build(adapter: 'sqlite3', connection: connection)
tables = wrapper.tables(:address_objects)

ActiveRecord::Schema.define do
  eval(importer.schema(tables))
end

bar = ProgressBar.new(wrapper.address_objects.record_count)

importer.import(tables) do
  bar.increment!
  break if bar.count == 100
end

puts Fias::AddressObject.first.inspect