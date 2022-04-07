class HammerstoneProductsFilter < ApplicationFilter
  def automatically_stabilize?
    true
  end

  # TODO fix this test
  def initial_query
    @initial_query || HammerstoneProduct.all
  end

  def table
    HammerstoneProduct.arel_table
  end

  def conditions
    [
      # 🚅 super scaffolding will insert new fields above this line.
      TextCondition.new("name"),
    ]
  end
end
