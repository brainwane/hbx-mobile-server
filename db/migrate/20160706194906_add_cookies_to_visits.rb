class AddCookiesToVisits < ActiveRecord::Migration
  def change
  	change_table :Visits do |t|
  		t.string :cookies
  	end 
  end
end
