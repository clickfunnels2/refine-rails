module Hammerstone::Refine::Stabilizers
  class StoredFilter < WorkspaceRecord
    self.table_name = "hammerstone_refine_stored_filters"

    shareable do
      exclude_sharing_attributes %w[id created_at updated_at]
    end
  end
end
