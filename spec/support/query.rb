class UndefinedQuery
  include Fias::Query
end

class TestQuery
  include Fias::Query

  def find(tokens)
    super
  end
end
