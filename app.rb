require 'sinatra/base'
require 'sinatra/config_file'
require 'json'
require 'hashie'
require 'uuid'
require 'jbuilder'
require 'rest_client'
require 'sqlite3'
require 'sequel'
require 'mechanize'
require 'htmlentities'

# All of the initializations happen in the call below
require_relative 'config/init'

#Configuration: http://www.sinatrarb.com/configuration.html
class HbxMobileServerApplication < Sinatra::Base
  register Sinatra::ConfigFile

  extend Helper
  enable :sessions
  set :protection, :except => [:http_origin]

  # Load all the app-level configurations. They are accessible via the "settings." prefix. Mongoid is loaded later below.
  Dir['config/*.yml'].map { |file| config_file file }

  # Include the nested modules dynamically.
  include_modules ::HbxMobileServer
  include_modules ::HbxMobileServer::Security
  include_modules ::Helpers::Security
end