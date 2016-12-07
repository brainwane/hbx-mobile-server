#
# This module defines ALL the routes for Login.
#
module HbxMobileServer
  module Security
    module AllMethods
      include Helper
      include Database::SQLite

      def self.included base

        #
        # POST /login
        #
        base.post '/login', :provides => :json do
          security = Services::Security.new settings, params
          security.authenticate { |security_question, visit, error|
            if error
              status error[:status]
              body error[:message]
            else
              p security_question
              status 202
              headers \
                'Location' => "#{request.env['REQUEST_URI']}/#{visit.id}"
              body({security_question: security_question}.to_json)
            end
          }
        end

        #
        # POST /login/:id
        #
        base.post '/login/:id', :provides => :json do
          security = Services::Security.new settings, params
          security.security_answer { |session_id, enroll_url, broker_endpoint, employer_details_endpoint, employee_roster_endpoint|
            body login_response_as_json(session_id, enroll_url, broker_endpoint, employer_details_endpoint,
                                        employee_roster_endpoint)
            status 201
          }
        end


      end #def self.included base
    end
  end
end