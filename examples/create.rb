# Can be run in cloned repo
# DATABASE_URL=postgres://localhost/fias bundle exec ruby create.rb

require 'pg_data_encoder'
require 'ruby-progressbar'
require 'sequel'
require 'active_support/core_ext/object/blank'
require 'fias'

def create_bar(count)
  ProgressBar.create(total: count, format: '%a |%B| [%E] (%c/%C) %p%%')
end

DB = Sequel.connect(ENV['DATABASE_URL'])

PREFIX = ENV['PREFIX'] || 'fias'

FIAS_ADDRESS_OBJECTS_TABLE_NAME =
  [PREFIX, 'address_objects'].delete_if(&:blank?).join('_').to_sym

FIAS_ADDRESS_OBJECTS = DB[FIAS_ADDRESS_OBJECTS_TABLE_NAME]

ADDRESS_OBJECTS_TABLE_NAME = :address_objects

ADDRESS_OBJECTS = DB[ADDRESS_OBJECTS_TABLE_NAME]

def create_table
  puts 'Creating target table...'

  DB.create_table(ADDRESS_OBJECTS_TABLE_NAME) do
    primary_key :id

    column :aoid, :uuid
    column :aoguid, :uuid
    column :parentguid, :uuid
    column :parent_id, :integer
    column :name, :text
    column :abbr, :text
    column :code, :text
    column :center, :boolean
  end
end

def copy_fias_data
  puts 'Copying data from FIAS...'

  encoder = PgDataEncoder::EncodeForCopy.new(
    column_types: { 0 => :uuid, 1 => :uuid, 2 => :uuid }
  )

  # Nonhistorical records
  scope = FIAS_ADDRESS_OBJECTS.where(livestatus: 1)

  bar = create_bar(scope.count)

  scope.each do |row|
    bar.increment

    encoder.add([
      row[:aoid],
      row[:aoguid],
      row[:parentguid],
      row[:formalname],
      row[:shortname],
      row[:code],
      row[:centerst].to_i > 0
    ])
  end

  io = encoder.get_io

  columns = %i(aoid aoguid parentguid name abbr code center)

  DB.copy_into(ADDRESS_OBJECTS_TABLE_NAME, columns: columns, format: :binary) do
    begin
      io.readpartial(65_536)
    rescue EOFError => _e
      nil
    end
  end
end

def restore_hierarchy
  puts 'Restoring parent_id values...'
  Fias::Import::RestoreParentId.new(ADDRESS_OBJECTS).restore
end

create_table
copy_fias_data
restore_hierarchy

# Uncomment this migration if you want to use closure_tree for hierarchies:
#
# DB.create_table(:address_object_hierarchies) do
#   column :ancestor_id, Integer
#   column :descendant_id, Integer
#   column :generations, Integer

#   index [:ancestor_id, :descendant_id, :generations]
#   index [:ancestor_id]
#   index [:descendant_id]
# end
#
# Use http://github.com/gzigzigzeo/pg_closure_tree_rebuild to fill it.
#
# Database ready!
