module Hammerstone::Refine
  # value object that holds all aspects of the client state related to the filter
  class FilterState
    include ActiveModel::Model

    attr_accessor :blueprint_json,
      :filter_class,
      :stable_id,
      :stored_filter_id,
      :client_id

    attr_reader :blueprint, :refine_filter, :filter_form

    def initialize(attrs)
      super
      @client_id ||= SecureRandom.uuid
      set_refine_filter_and_blueprint!
      set_filter_form!
    end

    def to_params
      {
        hammerstone_refine_filter_state: {
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
        @refine_filter = Hammerstone.stabilizer_class('Stabilizers::UrlEncodedStabilizer').new.from_stable_id(id: stable_id)
        @blueprint = @refine_filter.blueprint
      else
        json = blueprint_json || "[]"
        @blueprint = JSON.parse(json).map(&:deep_symbolize_keys)
        @refine_filter = filter_class.constantize.new(blueprint)
      end
    end

    def set_filter_form!
      @filter_form = Hammerstone::Refine::FilterForms::Form.new(@refine_filter, id: client_id)
    end

  end
end
