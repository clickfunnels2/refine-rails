class CreateContactsTags < ActiveRecord::Migration[6.1]
  def change
    create_table :contacts_tags do |t|
      t.references :contact, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
  end
end
