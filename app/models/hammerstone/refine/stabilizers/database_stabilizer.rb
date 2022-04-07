module Hammerstone::Refine::Stabilizers
  class DatabaseStabilizer

    def to_stable_id(filter:, name: nil)
      # Serialize the filter class and blueprint. Reference via id.
      model.find_or_create_by!(state: filter.state, name: name).id
    end

    def from_stable_id(id:, initial_query: nil)
      # Find the associated StoredFiler by id and return state. Decode to create blueprint
      state = ActiveSupport::JSON.decode(model.find(id).state).deep_symbolize_keys
      Hammerstone::Refine::Filter.from_state(state, initial_query)
    end

    def model
      Hammerstone::Refine::StoredFilter
    end
  end
end