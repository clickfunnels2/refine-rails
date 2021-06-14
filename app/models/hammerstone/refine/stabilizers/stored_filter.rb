module Hammerstone::Refine::Stabilizers
  class StoredFilter < ActiveRecord::Base
    self.table_name = "hammerstone_refine_stored_filters"
  end
end