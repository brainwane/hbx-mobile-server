#!/usr/bin/env ruby

require 'open3'


def capture_form(form_url, filename, params='')
	out, err, status = Open3.capture3("curl -L -v #{params} #{form_url}")

	err =~ /.*Set-Cookie: _session_id=([^ ;]*);/
	cookie = $1
  	out =~ /<meta name="csrf-token" content="([^"]*)"/
	token = $1

	File.open("out/#{filename}.html", 'w') { |f| f.write(out)}
	File.open("out/#{filename}_details.txt", 'w') { |f| f.write(" #{err} Status: #{status}")}
    [cookie, token]
end

cookie, token = capture_form('http://10.36.27.206:3000/users/sign_in', 'login_form')
print "\nGot cookie: #{cookie} \nGot token: #{token} "

cookie, token = capture_form('http://10.36.27.206:3000/users/sign_in', 'do_login', 
	"-d user[email]=frodo@shire.com -d user[password]=Test123! -d authenticity_token=#{token} -H 'Cookie: _session_id=#{cookie}'")
print "\nGot cookie: #{cookie} \nGot token: #{token} "

cookie, token = capture_form('http://10.36.27.206:3000/employers/employer_profiles/57167b16ea497f05d2000009?tab=home', 'employer_home', "-H 'Cookie: _session_id=#{cookie}'")
print "\nGot cookie: #{cookie} \nGot token: #{token} "




