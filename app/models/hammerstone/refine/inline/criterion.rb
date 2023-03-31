class Hammerstone::Refine::Inline::Criterion
  include ActiveModel::Model

  attr_accessor :stable_id,
    :client_id,
    :condition_id,
    :input,
    :position,
    :conjunction,
    :refine_filter

  # initialize a Crtierion object from a blueprint node
  def self.from_blueprint_node(node, **additional_attrs)
    attrs = node.deep_dup.merge(additional_attrs)
    attrs[:input_attributes] = attrs.delete[:input]
    if input_attrs = attrs[:input_attributes]
      input_attrs[:count_refinement_attributes] = input_attrs.delete(:count_refinement)
      input_attrs[:date_refinement_attributes] = input_attrs.delete(:date_refinement)
    end
    new(attrs)
  end

  # 
  # Returns a nested array of Criterion objects reflecting the grouping of the OR groups in a filter's blueprint
  def self.groups_from_filter(refine_filter, **attrs)
    return [] unless blueprint
    [].tap do |result|
      result.push([])
      refine_filter.blueprint.each_with_index do |node, i|
        case node[:word]
        when "or"
          result.push []
        when "and"
          next
        else
          criterion = from_blueprint_node(node, **attrs.merge(refine_filter: refine_filter, position: i))
          result.last.push criterion
        end
      end
    end
  end

  def attributes
    {
      stable_id: stable_id,
      client_id: client_id,
      condition_id: condition_id,
      input: input,
      position: position,
      conjunction: conjunction,
      input_attributes: input_attributes
    }.compact
  end

  def input_attributes
    input&.attributes
  end

  def input_attributes=(attrs = {})
    self.input ||= Input.new
    input.attributes = attrs
  end

  def to_key
    [client_id, position, conjunction].compact
  end

  def condition
    @condition ||= begin
      @refine_filter
        .instantiated_conditons
        .find { |c| c.id == condition_id })
    end
  end

  def form_fields_partial
    "hammerstone/refine/conditions/components/#{condition.component}"
  end

  class Input
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
      }
    end

    def count_refinement_attributes
      count_refinement&.attributes
    end

    def count_refinement_attributes=(attrs = {})
      self.count_refinement ||= NumericRefinement.new
      count_refinement.attributes = attrs
    end

    def date_refinement_attributes
      date_refinement&.attributes
    end

    def date_refinement_attributes=(attrs = {})
      self.date_refinement ||= DateRefinement.new
      date_refinement.attributes = attrs
    end
  end

  class NumericRefinement
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

  class DateRefinement
    include ActiveModel::Model

    attr_accessor :clause, :date1, :date2, :days

    def attributes
      {
        clause: clause,
        date1: date1,
        date2: date2,
        days: days
      }.compact
    end
  end

end
