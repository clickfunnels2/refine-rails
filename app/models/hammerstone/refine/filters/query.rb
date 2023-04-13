class Hammerstone::Refine::Filters::Query
  include ActiveModel::Model
  # View Model for the main section of the filter builder- the dynamic query form

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

  def clear_errors
    @criteria.each { |c| c.errors.clear }
  end

  def grouped_criteria
    # Allow for an empty blueprint
    return [] if @criteria.blank?
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

  def blueprint
    if @filter.blueprint&.any?
      @filter.blueprint
    else
      []
    end
  end

  def configuration
    @filter.configuration
  end


  # The json representation of conditions that is sent to the front end. 
  def available_conditions_attributes
    configuration[:conditions]
  end

  # TODO make this a more useful data with pointers to which criteria
  # each error goes with
  def error_messages
    @criteria.flat_map {|c| c.errors.full_messages }
  end

  private

  def add_criteria!
    @criteria = []
    blueprint.each.with_index do |criterion_attrs, index|
      @criteria << Hammerstone::Refine::Filters::Criterion.new(
        **criterion_attrs.merge(query: self, uid: index, position: index)
      )
    end
  end
end
