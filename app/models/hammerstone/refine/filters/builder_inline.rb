class Hammerstone::Refine::Filters::BuilderInline < Hammerstone::Refine::Filters::Builder
  # View model for building inline filters
  # Adds attributes for the position and conjunction of the next criterion

  attr_accessor :position, :conjunction

  def initialize(attrs = {})
    super
    self.position = position.to_i if position
  end

  def to_params
    super.deep_merge! hammerstone_refine_filters_builder: {
      conjunction: conjunction,
      position: position
    }
  end

  # For use with the Rails dom_id helper
  def to_key
    result = super
    result += [conjunction, position]
  end
end
