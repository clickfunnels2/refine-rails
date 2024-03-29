class Refine::Filters::Criterion
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
    errors.clear
    return true if type == "conjunction"
    begin
      query_for_validate = filter.initial_query || filter.model.all
      condition&.apply(input, filter.table, query_for_validate)
    rescue Refine::Conditions::Errors::ConditionClauseError => e
      e.errors.each do |error|
        errors.add(:base, :invalid, message: error.full_message)
      end
    end
  end

  def condition_attributes
    result = condition&.to_array(allow_errors: true)
    result.to_h
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
    elsif type != "conjunction"
      raise Refine::InvalidFilterError
    end
  end
end
