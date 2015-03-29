# Can be run in cloned repo
# DATABASE_URL=postgres://localhost/fias bundle exec ruby generate_index.rb

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
  puts 'Adding tokens field...'

  DB.alter_table(ADDRESS_OBJECTS_TABLE_NAME) do
    add_column :tokens, 'text[]'
    add_column :ancestry, 'integer[]'
    run 'CREATE INDEX idx_tokens on "address_objects" USING GIN ("tokens");'
  end
end

def ancestry_for(id)
  ADDRESS_OBJECTS
    .select(:id)
    .join(:address_object_hierarchies, ancestor_id: :id)
    .where(address_object_hierarchies__descendant_id: id)
    .order(:address_object_hierarchies__generations)
    .select_map(:id)
end

def tokenize
  puts 'Generating tokens for search...'

  scope = ADDRESS_OBJECTS

  bar = create_bar(scope.count)

  scope.select(:id, :name).each do |row|
    bar.increment

    tokens = Fias::Name::Split.split(row[:name])
    ancestry = ancestry_for(row[:id])

    ADDRESS_OBJECTS.where(id: row[:id]).update(
      tokens: Sequel.pg_array(tokens, :text),
      ancestry: Sequel.pg_array(ancestry, :integer)
    )
  end
end

alter_table
tokenize
