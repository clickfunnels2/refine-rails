module Hammerstone::Refine
  class StoredFilter 
    validates_presence_of :state
    self.table_name = "hammerstone_refine_stored_filters"

    def refine_filter
      Hammerstone.stabilizer_class('Stabilizers::DatabaseStabilizer').new.from_stable_id(id: id)
    end
  end
end