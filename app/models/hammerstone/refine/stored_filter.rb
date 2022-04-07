module Hammerstone::Refine
  class StoredFilter < WorkspaceRecord
    validates_uniqueness_of :name, scope: :workspace_id, allow_nil: true
    validates_presence_of :state
    self.table_name = "hammerstone_refine_stored_filters"

    shareable do
      exclude_sharing_attributes %w[id created_at updated_at]
    end

    def refine_filter
      Stabilizers::DatabaseStabilizer.new.from_stable_id(id: id)
    end
  end
end
