class Hammerstone::Refine::Filters::Criterion
  # View model that holds the state of individual criteria within the Filter query
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

  attr_accessor :query
  delegate :filter, to: :query, allow_nil: true

  attr_reader :condition

  def initialize(**attrs)
    super
    initialize_condition!
  end

  def validate!
    return if (input&.has_key?(:count_refinement) || input&.has_key?(:date_refinement))
    errors.clear
    return true if type == "conjunction"
    begin
      condition&.apply(input, filter.table, filter.initial_query || filter.fallback_initial_condition)
    rescue Hammerstone::Refine::Conditions::Errors::ConditionClauseError => e
      e.errors.each do |error|
        errors.add(:base, error.full_message)
      end
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

  def meta_for_refinement_clause(refinement)
    refinement_meta = refinement[:meta]
    selected_clause_id = input[refinement[:id].to_sym][:clause]
    clauses = refinement_meta[:clauses]
    selected_clause = clauses.find { |clause| clause[:id] == selected_clause_id }
    selected_clause[:meta]
  end

  def component
    condition.component.underscore
  end

  private

  def initialize_condition!
    @condition = query
      .available_conditions
      .find { |condition| condition.id == condition_id }
      .dup

    if @condition
      @condition.set_filter(filter)
      filter.translate_display(@condition)
    end
  end
end
