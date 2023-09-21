class Refine::Filters::Builder
  # View Model that holds all aspects of the client state related to the filter builder
  # This includes auxiliary state like client_id and selected stored filter id
  #
  # State for the main query builder form is held in #query which is an instance of 
  # Refine::Filters::Query
  include ActiveModel::Model

  attr_accessor :blueprint_json,
    :filter_class,
    :stable_id,
    :stored_filter_id,
    :client_id,
    :initial_query

  attr_reader :blueprint, :refine_filter, :query

  def initialize(attrs = {})
    super
    @client_id ||= SecureRandom.uuid
    set_refine_filter_and_blueprint!
    set_query!
  end

  def to_params
    {
      refine_filters_builder: {
        blueprint_json: blueprint.to_json,
        stable_id: stable_id,
        stored_filter_id: stored_filter_id,
        client_id: client_id,
        filter_class: filter_class
      }
    }
  end

  # For use with the Rails dom_id helper
  def to_key
    [client_id]
  end

  private

  def set_refine_filter_and_blueprint!
    if stable_id.present?
      @refine_filter = Refine::Rails.configuration.stabilizer_classes[:url].new.from_stable_id(id: stable_id, initial_query: initial_query)
      @blueprint = @refine_filter.blueprint
    else
      json = blueprint_json || "[]"
      @blueprint = JSON.parse(json).map(&:deep_symbolize_keys)
      @refine_filter = filter_class.constantize.new(blueprint, initial_query)
    end
  end

  def set_query!
    @query = Refine::Filters::Query.new(@refine_filter)
  end

end
