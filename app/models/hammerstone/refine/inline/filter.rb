class Hammerstone::Refine::Inline::Filter
  include ActiveModel::Model

  attr_accessor :stable_id, :client_id
  attr_reader :refine_filter

  delegate :blueprint, conditions: to: :refine_filter

  def initialize(attributes = {})
    super
    @refine_filter = Refine::Rails.configuration.stabilizer_classes[:url].new.from_stable_id(id: stable_id, initial_query: initial_query)
    @blueprint = @refine_filter.blueprint
    @blueprint_json = @blueprint.to_json
  end
end
