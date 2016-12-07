module Helpers
  module Security
    module Response

      def login_response_as_json session_id, enroll_url, broker_endpoint, employer_details_endpoint, employee_roster_endpoint
        Jbuilder.encode do |json|
          json.session_id session_id
          json.enroll_server enroll_url
          json.broker_endpoint broker_endpoint
          json.employer_details_endpoint employer_details_endpoint
          json.employee_roster_endpoint employee_roster_endpoint
        end
      end

    end
  end
end