class ProductsFilter < Refine::Filter
  def automatically_stabilize?
    true
  end

  # TODO fix this test
  def initial_query
    @initial_query || RefineProduct.all
  end

  def table
    RefineProduct.arel_table
  end

  def conditions
    [
      # 🚅 super scaffolding will insert new fields above this line.
      Refine::Conditions::TextCondition.new("name"),
    ]
  end
end
