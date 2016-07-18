require 'open3'
require 'net/https'
require 'open-uri'
require 'cgi'
require 'mechanize'
require 'json'




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



class ProdAndTestServerConfig
	def iam_home
		Rails.configuration.mobile_url_home
	end

	def iam_login_form
		Rails.configuration.mobile_url_iam_login_form
	end

	def iam_login
		Rails.configuration.mobile_url_iam_login
	end

	def iam_login_auth_jump
		Rails.configuration.mobile_url_iam_login_auth_jump
	end

	def iam_challenge_user
		Rails.configuration.mobile_url_iam_challenge_user
	end

	def enroll_url
		'https://enroll.dchealthlink.com/'
	end


	def username_password_post(email, password, params)
		print "In do_login\n"
		mechanize = Mechanize.new
		print "gem versions: \n"
		mechanize.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		print "server: #{iam_home}\n"
		req = mechanize.get(iam_home)
		print "get home:#{req.code}\n"
		#print req.body

		if req.code.to_i >= 400
		  print "error #{req.code}\n"
		  abort "error getting home page"
		end

		print "getting login form\n"
		req = mechanize.get(iam_login_form)
		print "got iam login form: #{req.code}\n"
		if (req.code.to_i >= 400)
		  print "error #{req.code}\n"
		  abort "error getting login page"
		end


		form_values = {:clientOffset =>-4 ,:userid => params[:userid], :pass=>params[:pass]}
		req = mechanize.post(iam_login, form_values)
		print "got iam_login: #{req.code}\n"
		if (req.code.to_i >= 400)
		  print "error #{req.code}\n"
		  abort "error posting login"
		end

		print "***login post worked\n"
		sleep 3.0
		req = mechanize.get(iam_login_auth_jump)
		print "get iam login auth jump: #{req.code}\n"
		if req.code.to_i >= 400
		  print "error getting iam login auth jump: #{req.code}\n"
		  abort "Error get login form"
		end

		html_entities = HTMLEntities.new
		body = req.body

		# Check to see if we successfully submitted username & password...
		error_matches = body.include?("<label for=\"userid\">Username<\/label>")
		print "include done\n"
		if error_matches
			print "raising\n"
			raise "bad login"
		end

		# Username & password submission were successfull!

		print "matching\n"
		matches = /<input type=\"hidden\" name=\"showView\" value=\"([^"]*)\" \/>/.match(body)
		print "decoding: #{matches}\n"
		print "decoding: #{matches[0]}\n"
		print "decoding: #{matches[1]}\n"
		show_view_value = html_entities.decode(matches[1])
		print "matching again\n"
		matches = /<input type="hidden" name="fk" value="([^"]*)" \/>/.match(body)
		fk = html_entities.decode(matches[1])
		hidden_values = {:fk => fk, :showView => show_view_value }

		# go see Ruchi

		matches = /<h3>([^\<]+)<\/h3>/.match(body)
		question = html_entities.decode(matches[1])
		print "question #{question}\n"
		print "showViewValue: #{show_view_value}\n"
		print "fk: #{fk}\n"
		print "***got auth Jump\n"

		string_stream = StringIO.new
		print "streaming cookies\n"
		mechanize.cookie_jar.save(string_stream, session: true)
		[question, string_stream.string, hidden_values.to_json]
	end

	def security_answer_post(params)
		print "#{Rails.application.config.eager_load}\n"
		print "In VisitsController.answer_security_question\n"
		print "#{params}\n"
		security_answer = params[:security_answer]
		print "got security_answer\n"
		id = params.values_at(:id)

		visit = Visit.find_by(id: id)
		if visit == nil
			raise "Not Found"
		end
		print visit
		print "************* hidden_fields: #{visit[:hidden_fields]}\n"

		mechanize = Mechanize.new
		mechanize.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE

		print "building string reader\n"
		reader = StringIO.new(visit["cookies"], "r")
		print "loading cookie_jar\n"
		mechanize.cookie_jar.load(reader)
		print "cookies:\n"
		print mechanize.cookies
		print "\n"
		form_values = {:register=>'Continue', :Bharosa_Challenge_PadDataField => security_answer }
		print "parsing json: #{visit[:hidden_fields]}\n"

		hidden_fields = JSON.parse(visit[:hidden_fields])
		print "foreach hidden_fields\n"
		hidden_fields.each { |key, value|
			form_values[key] = value
		}

		print "form values:\n#{form_values}\n"

		mechanize.redirect_ok = false
		req = mechanize.post(iam_challenge_user, form_values)
		code = req.code.to_i
		while code >= 300 && code < 400
		  location = req.response['location']
		  print "redirecting to #{location}\n"
		  req = mechanize.get location
		  code = req.code.to_i
		end

		print "finished manual redirects\n"
		mechanize.redirect_ok = true
		print "#{req.forms}\n"
		req = req.forms.first.submit
		session_id = {}
		cookies = mechanize.cookies
		cookies.each do |c|
		  print "domain #{c}\n"
		  if c.domain == 'enroll-preprod.dchbx.org'
		    if (c.name == '_session_id')
		      session_id = c.value
		    end
		  end
		end

		print "#{id}\n"
		print "#{security_answer}"
		{session_id: session_id, enroll_server: enroll_url}

	end
end



class DevServerConfig
	def username_password_post(username, password)
	end

	def security_answer_post(params)

	end
end

class VisitsController < ApplicationController

	@server_config


	def initialize
		@server_config = ""
		if Rails.env.development?
			print "*************running as dev server"
			@server_config = DevServerConfig.new
		else
			print "*************running as test or prod server"
    		@server_config = ProdAndTestServerConfig.new
		end
	end

	def answer_security_question
		render :json => @server_config.security_answer_post(params)
	end

	def create
		email, password, device_id = params_for_create.values_at(:userid, :password, :device_id)

		host = 'http://10.36.27.236:3000'

		#cookie, token = capture_form("#{host}/users/sign_in", 'login_form', "-H 'Accept: text/html'")
		#print "\nGot cookie: #{cookie} \nGot token: #{token} "

		#cookie, token = capture_form("#{host}/users/sign_in", 'do_login', 
		#	"-d user[email]=bill.murray@example.com -d user[password]=Test123! -d authenticity_token=#{CGI.escape(token)} -H 'Cookie: _session_id=#{cookie}'")
		#print "\nGot cookie POST: #{cookie} \nGot token: #{token} "

		security_question = ''
		cookies = ''
		hidden_values = {}
		begin
			print "Calling do_login\n"
			security_question, cookies, hidden_values = @server_config.username_password_post(email, password, params)
			print "back from do_login\n"
		rescue Exception => msg
			print msg
			render :json => {error: "Unable to contact security server"}, :status => 500
			abort
		end	

		if security_question == nil
			render :json => {error: "Not authorized", :status => 401}
		else
			@test = "token_time"
			#render :json => {session_key: cookie, csrf: token}
			visit = Visit.where(email: email).first_or_create
			visit["device_id"] = device_id
			visit["cookies"] = cookies
			visit["hidden_fields"] = hidden_values
			visit.save
			render :json => {security_question: security_question }, :status =>  202, :location => "/login/#{visit.id}"
		end
	end

	def update
	end

	def params_for_create
		params.permit(:userid, :password, :device_id)
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
	