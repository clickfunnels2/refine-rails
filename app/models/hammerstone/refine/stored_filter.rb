# This is client specific (inheriting from WorkspaceRecord). It's referenced in the client app everywhere as 
# Hammerstone::Refine::StoredFilter - I think the move is to completely remove this class from here and let each client 
# add it to their own repository, requiring the Hammerstone::Refine::StoredFilter namespacing (b/c this is what
# our controller expects)
# module Hammerstone::Refine
#   class StoredFilter < WorkspaceRecord
#     validates_uniqueness_of :name, scope: :workspace_id, allow_nil: true
#     validates_presence_of :state
#     self.table_name = "hammerstone_refine_stored_filters"

#     shareable do
#       exclude_sharing_attributes %w[id created_at updated_at]
#     end

#     def refine_filter
#       Hammerstone.stabilizer_class('Stabilizers::DatabaseStabilizer').new.from_stable_id(id: id)
#     end
#   end
# end
