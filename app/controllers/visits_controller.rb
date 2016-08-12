require 'open3'
require 'net/https'
require 'open-uri'
require 'cgi'
require 'mechanize'
require 'json'


#for ease of reading logs
def prefixed(multiline_text, prefix)
	multiline_text.split("\n").map { |line| "#{prefix}#{line}" }.join "\n"
end


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

def find_cookie_value(cookies, name, domain)
	print "looking for a cookie named #{name} with domain #{domain} in cookies #{cookies.inspect}\n\n"
	cookie = cookies.find { |c| c.domain == domain && c.name == name }
	if cookie
		cookie.value
	end
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
		Rails.configuration.enroll_url
	end

	def cookie_domain
		Rails.configuration.session_id_cookie_domain
	end

	def cookie_name
		Rails.configuration.session_id_cookie_name
	end

	def override_saml_enroll_url
		Rails.configuration.override_saml_enroll_url
	end

	def username_password_post(email, password, params)
		$stdout.sync = true # force autoflush to see logs for debugging
		print "ProdAndTestServerConfig.user_password_post\n"
		mechanize = Mechanize.new
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
		print "Post parameters: #{form_values}"
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

		print "body from login post:\n#{prefixed(body, "%%% ")}\n************\n"

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
		print "eager load = #{Rails.application.config.eager_load}\n"
		print "In VisitsController.answer_security_question\n"
		print "with params: #{params}\n"
		security_answer = params[:security_answer]
		print "got security_answer\n"
		id = params.values_at(:id)

		visit = Visit.find_by(id: id)
		if visit == nil
			raise "Corresponding visit not found, erroneous request"
		end
		print visit
		print "************* hidden_fields: #{visit[:hidden_fields]}\n"

		mechanize = Mechanize.new
		mechanize.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE

		print "building string reader\n"
		reader = StringIO.new(visit["cookies"], "r")
		print "loading cookie_jar\n"
		mechanize.cookie_jar.load(reader)
		print "cookies:\n #{mechanize.cookies}\n"
		form_values = {:register=>'Continue', :Bharosa_Challenge_PadDataField => security_answer }
		print "parsing json: #{visit[:hidden_fields]}\n"

		hidden_fields = JSON.parse(visit[:hidden_fields])
		print "storing each hidden field into the form values hash\n"
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
		print "req.forms: #{req.forms}\n"

		form = req.forms.first	

		#to use production IAM with a test enroll instance, override where the SAML is posted to	
		if override_saml_enroll_url
			form.action = form.action.gsub("enroll.dchealthlink.com", override_saml_enroll_url)
			form.RelayState = form.RelayState.gsub("enroll.dchealthlink.com", override_saml_enroll_url)
		end

		req = form.submit
		session_id = {}
		cookies = mechanize.cookies
		session_id = find_cookie_value(cookies, cookie_name, cookie_domain)

		print """caller responded to login/#{id} with security_answer #{security_answer}, returning:
		         session_id #{session_id}, enroll_server #{enroll_url}\n
		"""
		{session_id: session_id, enroll_server: enroll_url}

	end
end

class DevServerConfig
	def home
		Rails.configuration.mobile_url_home
	end

	def login_form
		Rails.configuration.mobile_url_login_form
	end

	def login
		Rails.configuration.mobile_url_login
	end

	def enroll_url
		Rails.configuration.enroll_url
	end

	def cookie_domain
		Rails.configuration.session_id_cookie_domain
	end

	def cookie_name
		Rails.configuration.session_id_cookie_name
	end

	def username_password_post(username, password, params)
		print "In DevServerConfig.user_password_post\n"
		mechanize = Mechanize.new
		mechanize.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		mechanize.redirection_limit = (10000)
		print "server: #{home}\n"
		req = mechanize.get(home)
		print "got home page: #{req.code}\n"
		if (req.code.to_i >= 400)
		  print "error #{req.code}\n"
		  abort "error getting login page"
		end
		
		print "getting login form at #{login_form}\n"
		req = mechanize.get(login_form)
		print "got login form: #{req.code}\n"
		if (req.code.to_i >= 400)
		  print "error #{req.code}\n"
		  abort "error getting login page"
		end

		get_cookies_stream = StringIO.new
		mechanize.cookie_jar.save(get_cookies_stream, session: true)
 		print "******************************\nreturned from mechanize.GET: \n"
		p req
		p req.response
		print "Cookies: #{ get_cookies_stream.string }"
        print "******************************\n"
		

		body = req.body
		matches = /<meta name=\"csrf-token\" content=\"([^"]+)\"/.match(body)
		print "authenticity_token: #{matches[1]}\n"
		form_values = {
			"user[email]" => params[:userid],
			"user[password]" => params[:pass],
			"authenticity_token" => matches[1]
		}
		print "posting to login(#{login}): #{form_values}\n"
		req = mechanize.post(login, form_values, {'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8', 'Accept' => "text/html"})
		print "got login: #{req.code}\n"
		if (req.code.to_i >= 400)
		  print "error #{req.code}\n"
		  abort "error posting login"
		end

        print "******************************\nreturned from mechanize.post: \n"
		p req
		p req.response
        print "******************************\n"

		string_stream = StringIO.new
		print "streaming cookies\n"
		mechanize.cookie_jar.save(string_stream, session: true)
		["This is the dev security question", string_stream.string, {}]
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

		print mechanize.cookies
		session_id = ''
		cookies = mechanize.cookies
		session_id = find_cookie_value(cookies, cookie_name, cookie_domain)

		print "#{id}\n"
		print "#{security_answer}"
		{session_id: session_id, enroll_server: enroll_url}
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
		print "In VisitsController.create\n"

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

		print "checking security_question\n"
		if security_question == nil
			render :json => {error: "Not authorized", :status => 401}
		else
			@test = "token_time"
			#render :json => {session_key: cookie, csrf: token}
			print "calling first_or_create\n"
			visit = Visit.where(email: email).first_or_create
			print "back from first_or_create\n"
			visit["device_id"] = device_id
			visit["cookies"] = cookies
			visit["hidden_fields"] = hidden_values
			visit.save
			render :json => {security_question: security_question }, 
			       :status =>  202, 
			       :location => "#{request.env['REQUEST_URI']}/#{visit.id}"
		end
	end

	def update
	end

	def params_for_create
		print "In VisitsController.params_for_create\n"
		params.permit(:userid, :pass, :device_id)
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
	