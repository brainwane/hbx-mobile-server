#!/usr/bin/env ruby

require 'open3'
require 'cgi'
require 'net/http'
require 'openssl'
require 'restclient'
#host = 'http://10.36.27.206:3000'
#host = 'http://localhost:3000'
host = 'http://www.yahoo.com'

redirectLimit = 15

server = {
	:iam_home=> 'https://preprod.dchealthlink.com',
	:iam_login_form=> 'https://preprod.dchealthlink.com/login-sso',
	:iam_login=> 'https://webpp.dchealthlink.com/oaam_server/loginAuth.do',
	:iam_login_auth_jump=> 'https://webpp.dchealthlink.com/oaam_server/authJump.do?jump=false'
}

def set_cookie_headers(http, cookies)
	print "set_cookie_headers http: #{http}"
	if cookies != nil then
		cookies.each do |c|
			http["Cookie"] = c
		end
	else
		print "No cookies to set\n"
	end
end

def set_cookies_for_request(req, cookies)
	if cookies != nil then

		print ("@@@@@@@@@@@@@@@@@@@@#{cookies}\n")
		cookies.each do |c|
			req.add_field('Cookie', c);
		end
		File.open("out/cookies.txt", 'a') do
			|f|
			cookies.each do |c|
				f.write("sending #{c}\n")
			end
		end
	else
		print "No cookies to set\n"
	end
end

def get_new_cookies(response)
	arr = []
	cookies = response.each do |h|
		if h == "set-cookie" then
			print "found cookie to split ************#{h}\n"
			#	If we need better cookie handling this is one
			#	place it needs to be done.
		    arr.push(response[h].split(/ |;/).first())
		end
	end
	#print "&&&&&&&&&\n"
	#arr.each do |c|
	#	print "#{c}\n"
	#end
	#print "&&&&&&&&&\n"
	File.open("out/cookies.txt", 'a') {
	 	|f|
	 	arr.each do |c|
	 		f.write("rcvd #{c}\n")
	 		f.write("--------------\n")
	 	end
	 	f.write("*************\n")
	}
	arr
end

def get_form(form_url, filename, limit, outgoingCookies=nil)
	if form_url == nil || form_url.length < 1
		raise 'form_url can\'t be empty or nil.'
	end
	print("Getting from: #{form_url}\n")
	uri = URI(form_url)
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE # read into this
	req = Net::HTTP::Get.new(uri.request_uri)
	set_cookies_for_request(req, outgoingCookies)
	response = http.request(req)

	print "back from get, response: #{response}\n"

	case response
	when Net::HTTPRedirection then
		print "getting cookies\n"
		cookies = get_new_cookies(response)
		print "redirecting\n"
		return get_form(response['location'], filename, limit - 1, cookies)
	when response.code.to_i < 200 && response.code.to_i >= 300 then
		print "error (code: #{response.code})\n"
		abort "Error getting form_url"
	else
		print "Success getting #{form_url}\n"
	end


	print "getting cookies\n"
	cookies = get_new_cookies(response)

	File.open("out/#{filename}.html", 'w') { |f| f.write(response.body)}
	File.open("out/#{filename}_details.txt", 'w') { |f| f.write(" #{response} Status: #{response.code}")}
    [cookies, response.body]
end

def post_form(form_url, filename, limit, parameters, outgoingCookies=nil)
	if form_url == nil || form_url.length < 1
		raise 'form_url can\'t be empty or nil.'
	end


	print("***********Posting to: #{form_url}\n")
	uri = URI(form_url)
	http = Net::HTTP.new(uri.host, uri.port)
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE # read into this
	http.use_ssl = true
	req = Net::HTTP::Post.new(uri.request_uri)
	req.set_form_data(parameters)
	set_cookies_for_request(req, outgoingCookies)
	response = http.request(req)

	print "back from post response: #{response}\n"

	case response
	when Net::HTTPRedirection then
		print "post redirecting\n"
		return get_form(response['location'], filename, limit - 1, outgoingCookies)
	when response.code.to_i < 200 && response.code.to_i >= 300 then
		print "error (code: #{response.code})\n"
		print "this is httpsuccess: #{Net.HTTPSuccess}"
		return "error"
	end


	print "getting cookies"
	cookies = get_new_cookies(response)

	File.open("out/#{filename}.html", 'w') { |f| f.write(response.body)}
	File.open("out/#{filename}_details.txt", 'w') { |f| f.write(" #{response} Status: #{response.code}")}
    cookies
end
	

	File.open("out/cookies.txt", 'w') {
	 	|f|
	 	f.write("***************\n")
	}


cookies, form = get_form(server[:iam_home], 'login_form', redirectLimit, nil)
if cookies == nil
	print "cookies is nil\n"
elsif cookies == "error"
	print "Error getting stuff\n"
	abort "Error get home form"
end

print "--------------------got home\n"

cookies, form = get_form(server[:iam_login_form], 'login_form', redirectLimit, cookies)
if cookies == nil
	print "cookies is nil\n"
elsif cookies == "error"
	abort "Error get login form"
end

print "--------------------got login\n"

print "Posting login\n"
formValues = {:clientOffset =>'-4' ,:userid => 'restonrider005', :pass=>"Duniya!1"}
cookies, login_form = post_form(server[:iam_login], 'login_form', redirectLimit, formValues, cookies)
if cookies == nil
	print "cookies is nil\n"
elsif cookies == "error"
	print "Error getting stuff\n"
end

print "--------------------login post worked\n"

cookies, form = get_form(server[:iam_login_auth_jump], 'login_form', redirectLimit, cookies)
if cookies == nil
	print "cookies is nil\n"
elsif cookies == "error"
	abort "Error get login form"
end

print "--------------------got auth Jump\n"



#cookie, token = capture_form("#{host}/users/sign_in", 'do_login', 
#	"-d user[email]=frodo@shire.com -d user[password]=Test123! -d authenticity_token=#{CGI.escape(token)} -H 'Cookie: _session_id=#{cookie}'")
#print "\nGot cookie: #{cookie} \nGot token: #{token} "
#
#cookie, token = capture_form("#{host}/employers/employer_profiles/57167b16ea497f05d2000009?tab=home", 'employer_home', "-H 'Cookie: _session_id=#{cookie}'")
#print "\nGot cookie: #{cookie} \nGot token: #{token} "




