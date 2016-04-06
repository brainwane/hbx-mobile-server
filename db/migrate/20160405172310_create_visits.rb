class CreateVisits < ActiveRecord::Migration
  def change
    create_table :visits do |t|
      t.string :email
      t.string :device_id

      t.timestamps null: false
    end
  end
end
