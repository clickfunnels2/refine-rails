# This is client specific (inheriting from WorkspaceRecord). It's referenced in the client app everywhere as
# Hammerstone::Refine::StoredFilter - I think the move is to completely remove this class from here and let each client
# add it to their own repository, requiring the Hammerstone::Refine::StoredFilter namespacing (b/c this is what
# our controller expects)

if Rails.env.test?
	module Hammerstone::Refine
	  class StoredFilter < ApplicationRecord
	    validates_presence_of :state
	    self.table_name = "hammerstone_refine_stored_filters"

	    def refine_filter
	      Hammerstone.stabilizer_class('Stabilizers::DatabaseStabilizer').new.from_stable_id(id: id)
	    end

      def blueprint
        JSON.parse(state)["blueprint"]
      end
	  end
	end
end
