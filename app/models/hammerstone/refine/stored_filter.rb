module Hammerstone::Refine
  class StoredFilter < ApplicationRecord
    validates_presence_of :state
    self.table_name = "hammerstone_refine_stored_filters"

    def refine_filter(initial_query: nil)
      Refine::Rails.configuration.stabilizer_classes[:db].new.from_stable_id(id: id, initial_query: initial_query)
    end

    def blueprint
      JSON.parse(state)["blueprint"]
    end
  end
end
