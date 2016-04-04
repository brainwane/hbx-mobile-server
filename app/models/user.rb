class User
  include Mongoid::Document
  field :first_name, type: String
  field :last_name, type: String
  field :email, type: String
  field :password, type: String
  field :password_confirmation, type: String
  field :temp_password, type: String    
end
