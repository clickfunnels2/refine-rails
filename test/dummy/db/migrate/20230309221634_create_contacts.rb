class CreateContacts < ActiveRecord::Migration[7.0]
  def change
    create_table :contacts do |t|
      t.binary :avatar
      t.boolean :active
      t.date :birthday
      t.datetime :last_login
      t.decimal :salary
      t.float :height
      t.integer :age
      t.string :name
      t.text :bio
      t.time :wake_up_time
      t.json :preferences
      t.json :data
      t.json :tags

      t.timestamps
    end
  end
end
