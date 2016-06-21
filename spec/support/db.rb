DB = {}
SHORTCUTS = {}

YAML.load_file('spec/fixtures/addressing.yml').each.with_index do |item, index|
  parentage = item.inject([]) do |parentage, element|
    name = element.last
    name, _, abbr, _ = Fias::Name::Extract.extract(name)
    tokens = Fias::Name::Synonyms.tokens(name)
    forms = Fias::Name::Synonyms.forms(name)
    id = DB.size + 1

    DB[id] = {
      id: id,
      parent_id: parentage.last,
      name: name,
      abbr: abbr,
      parentage: parentage.reverse,
      tokens: tokens,
      forms: forms
    }

    parentage + [id]
  end

  SHORTCUTS[index] = DB[parentage.last]
end

def find_in_addressing_db(tokens)
  DB.values.find_all { |record| (record[:tokens] & tokens).size > 0 }.dup
end
