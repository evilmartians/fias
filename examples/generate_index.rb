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
    add_column :parentage, 'integer[]'
    add_column :forms, 'text[]'
  end

  DB.run 'CREATE INDEX idx_tokens on "address_objects" USING GIN ("tokens");'
end

def parentage_for(id)
  ADDRESS_OBJECTS
    .select(:id)
    .join(:address_object_hierarchies, ancestor_id: :id)
    .where(address_object_hierarchies__descendant_id: id)
    .order(:address_object_hierarchies__generations)
    .select_map(:id) - [id]
end

def tokenize
  puts 'Generating tokens for search...'

  scope = ADDRESS_OBJECTS

  bar = create_bar(scope.count)

  scope.select(:id, :name).each do |row|
    bar.increment

    tokens = Fias::Name::Synonyms.tokens(row[:name])
    forms = Fias::Name::Synonyms.forms(row[:name])
    parentage = parentage_for(row[:id])

    ADDRESS_OBJECTS.where(id: row[:id]).update(
      tokens: Sequel.pg_array(tokens, :text),
      forms:  Sequel.pg_array(forms, :text),
      parentage: Sequel.pg_array(parentage, :integer)
    )
  end
end

alter_table
tokenize
