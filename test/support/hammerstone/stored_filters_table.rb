module Hammerstone::Refine::Stabilizers
  # class CreateStoredFiltersTable < ActiveRecord::Migration[6.1]
  #   def up
  #     create_table :hammerstone_refine_stored_filters, if_not_exists: true do |t|
  #       t.json :state

  #       t.timestamps
  #     end
  #   end

  #   def down
  #     drop_table :hammerstone_refine_stored_filters, if_exists: true
  #   end
  # end

  class StoredFilter < ActiveRecord::Base
    self.table_name = "hammerstone_refine_stored_filters"
  end
end
