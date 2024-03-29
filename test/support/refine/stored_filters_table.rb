class CreateStoredFiltersTable < ActiveRecord::Migration[6.1]
  def up
    create_table :refine_stored_filters, if_not_exists: true do |t|
      t.json :state
      t.string "filter_type"
      t.string "name"
      t.timestamps
    end
  end

  def down
    drop_table :refine_stored_filters, if_exists: true
  end
end


