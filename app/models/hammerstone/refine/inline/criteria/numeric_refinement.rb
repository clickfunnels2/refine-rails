class Hammerstone::Refine::Inline::Criteria::NumericRefinement
  include ActiveModel::Model

  attr_accessor :clause, :value1, :value2

  def attributes
    {
      clause: clause,
      value1: value1,
      value2: value2
    }.compact
  end
end
