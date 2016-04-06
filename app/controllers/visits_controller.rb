class VisitsController < ApplicationController

	def create
		email, password, device_id = params_for_create.values_at(:email, :password, :device_id)

		if saml_token = authenticate?(email, password)
			visit = Visit.where(email: email).first_or_create
			visit["device_id"] = device_id
			visit.save
			if session_key = establish_session(saml_token)
				render :json => {session_key: session_key}
			else 
				render :json => {error: "Cannot establish a valid connection to the Enroll Application"}, :status => 503
			end
		else
			render :json => {error: "Email/password combination not found"}, :status => 403
		end
	end

	def params_for_create
		params.permit(:email, :password, :device_id)
	end

	def authenticate?(email, password)
		#TODO: call IAM, authenticate, return SAML or nil for failure
		#for now, we mock it by failing on a password of "fail"
		"some_saml" unless password == "fail"
	end

	def establish_session(saml_token)
		#TODO: call EnrollApp with SAML, create session key
		"SESSION_KEY000"
	end
end
