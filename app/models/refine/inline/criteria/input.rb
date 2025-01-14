class Refine::Inline::Criteria::Input
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
  :count_refinement,
  :date_refinement


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
      count_refinement: count_refinement_attributes.presence,
      date_refinement: date_refinement_attributes.presence
    }.compact
  end

  def attributes=(attrs = {})
    super(attrs)
    strip_values
  end

  def count_refinement
    @count_refinement ||= Refine::Inline::Criteria::NumericRefinement.new
  end

  def count_refinement_attributes
    count_refinement.attributes
  end

  def count_refinement_attributes=(attrs = {})
    count_refinement.attributes = attrs.to_h
  end

  def date_refinement
    @date_refinement ||= Refine::Inline::Criteria::DateRefinement.new
  end

  def date_refinement_attributes
    date_refinement.attributes
  end

  def date_refinement_attributes=(attrs = {})
    date_refinement.attributes = attrs.to_h
  end

  def selected=(value)
    @selected = Array.wrap(value)
  end

  def strip_values
    [:value, :value1, :value2].each do |attr|
      current_value = send(attr)
      send("#{attr}=", current_value.strip) if current_value.present?
    end
  end
end
