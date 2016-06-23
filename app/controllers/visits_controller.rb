require 'open3'
require 'net/https'
require 'open-uri'
require 'cgi'

def capture_form(form_url, filename, params='')
	#out, err, status = Open3.capture3("curl -L -v #{params} #{form_url}")
	out, err, status = Open3.capture3("curl -L -v #{params} #{form_url}")

	err =~ /.*Set-Cookie: _session_id=([^ ;]*);/
	cookie = $1
  	out =~ /<meta name="csrf-token" content="([^"]*)"/
	token = $1

#STDOUT.puts err
#URI::encode(str)


	[cookie, token]
end

class VisitsController < ApplicationController

	def create
		email, password, device_id = params_for_create.values_at(:email, :password, :device_id)

		host = 'http://10.36.27.236:3000'

		cookie, token = capture_form("#{host}/users/sign_in", 'login_form', "-H 'Accept: text/html'")
		print "\nGot cookie: #{cookie} \nGot token: #{token} "

		cookie, token = capture_form("#{host}/users/sign_in", 'do_login', 
			"-d user[email]=bill.murray@example.com -d user[password]=Test123! -d authenticity_token=#{CGI.escape(token)} -H 'Cookie: _session_id=#{cookie}'")
		print "\nGot cookie POST: #{cookie} \nGot token: #{token} "

		@test = "token_time"
		#render :json => {session_key: cookie, csrf: token}
		if saml_token = authenticate?(email, password)
			visit = Visit.where(email: email).first_or_create
			visit["device_id"] = device_id
			visit.save
			if session_key = establish_session(saml_token)
				render :json => {session_key: "_session_id=#{cookie}", enroll_server: "10.36.27.236:3000", security_question: "What is your favorite color????" }
				#render :json => {session_key: session_key}
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
