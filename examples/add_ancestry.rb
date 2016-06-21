# Can be run in cloned repo
# DATABASE_URL=postgres://localhost/fias bundle exec ruby add_ancestry.rb
#
# Start this task only when you had finished generate index with parentage column.

require 'ruby-progressbar'
require 'sequel'
require 'active_support/core_ext/object/blank'
require 'fias'

def create_bar(count)
  ProgressBar.create(total: count, format: '%a |%B| [%E] (%c/%C) %p%%')
end

DB = Sequel.connect(ENV['DATABASE_URL'])
DB.extension :pg_array

ADDRESS_OBJECTS_TABLE_NAME = :address_objects
ADDRESS_OBJECTS = DB[ADDRESS_OBJECTS_TABLE_NAME]

def alter_table
  puts 'Adding ancestry field...'

  DB.alter_table(ADDRESS_OBJECTS_TABLE_NAME) do
    add_column :ancestry, 'text'
  end

  DB.run 'CREATE INDEX idx_ancestry ON "address_objects" USING BTREE ("ancestry");'
end

def ancestry
  puts 'Building ancestry...'

  scope = ADDRESS_OBJECTS

  bar = create_bar(scope.count)

  scope.select(:id, :parentage).each do |row|
    bar.increment

    ADDRESS_OBJECTS.where(id: row[:id]).update(
        ancestry: row[:parentage].reverse.join('/')
    ) unless row[:parentage].empty?
  end
end

alter_table
ancestry
