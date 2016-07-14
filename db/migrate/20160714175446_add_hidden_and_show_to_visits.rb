class AddHiddenAndShowToVisits < ActiveRecord::Migration
  def change
    add_column :visits, :hidden_values, :string
  end
end
