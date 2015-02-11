# DATABASE_URL=postgres://localhost/fias bundle exec ruby create.rb

require 'pg_data_encoder'
require 'ruby-progressbar'
require 'sequel'
require 'active_support/core_ext/object/blank'

def create_bar(count)
  ProgressBar.create(total: count, format: '%a |%B| [%E] (%c/%C) %p%%')
end

DB = Sequel.connect(ENV['DATABASE_URL'])

PREFIX = ENV['PREFIX'] || 'fias'

FIAS_ADDRESS_OBJECTS_TABLE_NAME =
  [PREFIX, 'address_objects'].delete_if(&:blank?).join('_').to_sym

FIAS_ADDRESS_OBJECTS = DB[FIAS_ADDRESS_OBJECTS_TABLE_NAME]

ADDRESS_OBJECTS_TABLE_NAME = :address_objects

DB.create_table!(ADDRESS_OBJECTS_TABLE_NAME) do
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

puts 'Target table created.'

ADDRESS_OBJECTS = DB[ADDRESS_OBJECTS_TABLE_NAME]

# Copy nonhistorical records
puts 'Copying data from FIAS...'

encoder = PgDataEncoder::EncodeForCopy.new(
  column_types: { 0 => :uuid, 1 => :uuid, 2 => :uuid }
)

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

# Calculate hierarchy fields
