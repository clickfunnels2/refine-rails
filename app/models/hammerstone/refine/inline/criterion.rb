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

    # delete some attributes we don't need
    attrs.delete(:depth)
    attrs.delete(:type)

    # suffix nested hash keys with '_attributes' to initialize objects
    attrs[:input_attributes] = attrs.delete(:input)
    if input_attrs = attrs[:input_attributes]
      input_attrs[:count_refinement_attributes] = input_attrs.delete(:count_refinement)
      input_attrs[:date_refinement_attributes] = input_attrs.delete(:date_refinement)
    end
    new(attrs)
  end

  # 
  # Returns a nested array of Criterion objects reflecting the grouping of the OR groups in a filter's blueprint
  def self.groups_from_filter(refine_filter, **attrs)
    return [] unless refine_filter&.blueprint.present?
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
      position: position,
      conjunction: conjunction,
      input_attributes: input_attributes
    }.compact
  end

  def to_params
    {hammerstone_refine_inline_criterion: attributes}
  end

  def input
    @input ||= Hammerstone::Refine::Inline::Criteria::Input.new
  end

  def input_attributes
    input.attributes
  end

  def input_attributes=(attrs = {})
    input.attributes = attrs.to_h
  end

  def to_key
    [client_id, position, conjunction].compact
  end

  def condition
    @condition ||= begin
      @refine_filter
        .instantiated_conditions
        .find { |c| c.id == condition_id }
    end
  end

  def input_partial
    "hammerstone/refine/inline/inputs/#{condition.component}".underscore
  end

  def to_blueprint_node
    result = attributes.slice(:condition_id, :input_attributes)
    result[:input] = result.delete(:input_attributes)
    if input_attrs = result[:input]
      input_attrs[:count_refinement] = input_attrs.delete(:count_refinement_attributes)
      input_attrs[:date_refinement] = input_attrs.delete(:date_refinement_attributes)
    end
    result
  end

  def human_readable
    condition.human_readable(to_blueprint_node[:input])
  end

  def options
    if condition.respond_to? :options
      condition.options.map {|option_hash| Hammerstone::Refine::Inline::Criteria::Option.new(**option_hash)}
    end
  end

  def multiple?
    selected_clause = condition.clauses.detect {|c| c.id == input.clause } || condition.clauses.first
    selected_clause.meta[:multiple].present?
  end
end
