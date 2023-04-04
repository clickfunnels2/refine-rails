class Hammerstone::Refine::Inline::Criteria::Input
  include ActiveModel::Model

  attr_accessor :clause,
  :date1,
  :date2,
  :days,
  :selected,
  :value,
  :value1,
  :value2,
  :count_refinement,
  :date_refinement

  def attributes
    {
      clause: clause,
      date1: date1,
      date2: date2,
      days: days,
      selected: selected,
      value: value,
      value1: value1,
      value2: value2,
      count_refinement_attributes: count_refinement_attributes,
      date_refinement_attributes: date_refinement_attributes
    }.compact
  end

  def count_refinement_attributes
    count_refinement&.attributes
  end

  def count_refinement_attributes=(attrs = {})
    self.count_refinement ||= Hammerstone::Refine::Inline::Criteria::NumericRefinement.new
    count_refinement.attributes = attrs
  end

  def date_refinement_attributes
    date_refinement&.attributes
  end

  def date_refinement_attributes=(attrs = {})
    self.date_refinement ||= Hammerstone::Refine::Inline::Criteria::DateRefinement.new
    date_refinement.attributes = attrs
  end
end
