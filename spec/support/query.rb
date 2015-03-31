class UndefinedQuery
  include Fias::Query
end

class TestQuery
  include Fias::Query

  def find(tokens)
    return [] if tokens.empty?

    find_in_addressing_db(tokens)
  end
end
