module Database
  module Model
    class Visit < Sequel::Model
      extend Database::SQLite

      def self.create_visit cookies, device_id, email, hidden_values
        visit = find_or_create email: email
        visit['device_id'] = device_id
        visit['cookies'] = cookies
        visit['hidden_fields'] = hidden_values
        persist visit
        visit
      end

    end
  end
end