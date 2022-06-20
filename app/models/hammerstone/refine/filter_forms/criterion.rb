class Hammerstone::Refine::FilterForms::Criterion
  # View model that holds the state of individual criteria within the Filter form
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :depth, :integer
  attribute :criterion, :string
  attribute :condition_id, :string
  attribute :input
  attribute :word, :string
  attribute :type, :string
  attribute :position, :integer
  attribute :uid, :string

  attr_accessor :form
  delegate :filter, to: :form, allow_nil: true

  attr_reader :condition

  def initialize(**attrs)
    super
    initialize_condition!
  end

  def validate!
    errors.clear
    return true if type == "conjunction"
    begin
      condition&.apply(input, filter.table, filter.initial_query)
    rescue Hammerstone::Refine::Conditions::Errors::ConditionClauseError => e
      errors.add :base, e.message
    end
  end

  def condition_attributes
    condition.to_array(allow_errors: true)
  end

  def meta
    condition_attributes[:meta]
  end

  def selected_clause
    input[:clause]
  end

  def selected_clause_meta
    meta[:clauses].find {|c| c[:id] == selected_clause }[:meta]
  end

  def refinements
    condition.refinements_to_array
  end

  private

  def initialize_condition!
    @condition = form
      .available_conditions
      .find { |condition| condition.id == condition_id }
      .dup

    if @condition
      @condition.set_filter(filter)
      label_fallback = {default: condition.id.humanize(keep_id_suffix: true).titleize}
      @condition.display ||= I18n.t(
        ".filter.conditions.#{@condition.id}.label",
        default: I18n.t(".fields.#{@condition.id}.label", **label_fallback)
      )
    end
  end
end
