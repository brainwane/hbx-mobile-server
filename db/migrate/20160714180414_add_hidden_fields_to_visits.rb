class AddHiddenFieldsToVisits < ActiveRecord::Migration
  def change
    add_column :visits, :hidden_fields, :string
  end
end
