class Hammerstone::Refine::Inline::Criteria::Input
  include ActiveModel::Model

  MODIFIERS = {
    ago: "days ago",
    from_now: "days from now"
  }.freeze

  attr_accessor :clause,
  :date1,
  :date2,
  :days,
  :modifier,
  :selected,
  :value,
  :value1,
  :value2,
  :count_refinement

  def attributes
    {
      clause: clause,
      date1: date1,
      date2: date2,
      days: days,
      modifier: modifier,
      selected: selected,
      value: value,
      value1: value1,
      value2: value2,
      count_refinement_attributes: count_refinement_attributes.presence
    }.compact
  end

  def count_refinement
    @count_refinement ||= Hammerstone::Refine::Inline::Criteria::NumericRefinement.new
  end

  def count_refinement_attributes
    count_refinement.attributes
  end

  def count_refinement_attributes=(attrs = {})
    count_refinement.attributes = attrs.to_h
  end

  def selected=(value)
    @selected = Array.wrap(value)
  end
end
