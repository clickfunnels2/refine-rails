class Hammerstone::Refine::FilterForms::Form
  # Presenter model for Blueprint Data

  def initialize(filter)
    @filter = filter
    add_criteria!
  end

  def validate!
    @criteria.each do |criterion|
      next if criterion.type == "conjunction"
      begin
        condition_for_criterion(criterion)&.apply(criterion.input, @filter.table, @filter.initial_query)
      rescue Hammerstone::Refine::Conditions::Errors::ConditionClauseError => e
        criterion.errors.add :base, e.message
      end
    end
  end

  def grouped_criteria
    [].tap do |result|
      # start with an empty group
      result.push []
      @criteria.each_with_index do |criterion, index|
        if criterion.word == "or"
          result.push []
        elsif criterion.word == "and"
          next
        else
          criterion.position = criterion.uid = index
          result.last.push criterion
        end
      end
    end
  end

  private

  def blueprint
    if @filter.blueprint&.any?
      @filter.blueprint
    else
      first_condition = conditions_attributes.first
      meta = first_condition[:meta]

      [{
        depth: 1,
        type: "criterion",
        condition_id: first_condition[:id],
        input: {clause: meta[:clauses][0][:id]},
      }]
    end
  end

  def add_criteria!
    @criteria = []
    blueprint.each do |criterion_attrs|
      @criteria << Hammerstone::Refine::FilterForms::Criterion.new(**criterion_attrs)
    end
  end

  def conditions
    @filter.conditions
  end

  def conditions_attributes
    @filter.conditions_to_array
  end

  def condition_for_criterion(criterion)
    result = conditions.find { |condition| condition.id == criterion.condition_id }
    if result
      instantiate_condition(result)
    end
    result.dup
  end

  def instantiate_condition(condition_class)
    condition_class.set_filter(@filter)
    translate_display(condition_class)
    condition_class
  end

  def translate_display(condition)
    # If there are no locale definitions for this condition's subject, we can allow I18n to use a human-readable version of the ID.
    # But, ideally, they have locales defined and we can find one of those.
    label_fallback = {default: condition.id.humanize(keep_id_suffix: true).titleize}
    condition.display ||= I18n.t(
      ".filter.conditions.#{condition.id}.label",
      default: I18n.t(".fields.#{condition.id}.label", **label_fallback)
    )
  end

end
