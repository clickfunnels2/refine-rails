class Hammerstone::Refine::FilterForms::Form
  # View Model that holds the state of the entire filter

  attr_reader :filter

  def initialize(filter)
    @filter = filter
    add_criteria!
  end

  def validate!
    @criteria.each(&:validate!)
  end

  def valid?
    validate!
    @criteria.all? { |c| c.errors.empty? }
  end

  def grouped_criteria
    [].tap do |result|
      # start with an empty group
      result.push []
      @criteria.each_with_index do |criterion, index|
        case criterion.word
        when "or"
          result.push []
        when "and"
          next
        else
          result.last.push criterion
        end
      end
    end
  end

  def available_conditions
    @filter.conditions
  end

  private

  def blueprint
    if @filter.blueprint&.any?
      @filter.blueprint
    else
      first_condition = available_conditions_attributes.first
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
    blueprint.each.with_index do |criterion_attrs, index|
      @criteria << Hammerstone::Refine::FilterForms::Criterion.new(
        **criterion_attrs.merge(form: self, uid: index, position: index)
      )
    end
  end

  def available_conditions_attributes
    @filter.conditions_to_array
  end
end
