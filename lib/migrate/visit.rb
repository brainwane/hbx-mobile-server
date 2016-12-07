module Database
  module Migrate
    class Visit

      def self.create_table
        return if DB.tables.include? :visits
        DB.create_table :visits do
          primary_key :id
          String :email
          String :device_id
          DateTime :created_at, null: false, default: Time.now
          DateTime :updated_at, null: false, default: Time.now
          String :cookies
          String :hidden_values
          String :hidden_fields
        end
      end

    end
  end
end