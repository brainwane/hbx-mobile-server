require 'simplecov'
require 'rack/test'
require 'factory_girl'
require 'json_spec'
require 'faker'

require_relative '../app'

ENV['RACK_ENV'] = 'test'

Dir[File.dirname(__FILE__) + './factories/*.rb'].each { |file| require file }
FactoryGirl.find_definitions

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.include FactoryGirl::Syntax::Methods
  conf.include JsonSpec::Helpers
end

def app
  @app ||= HbxMobileServerApplication
end

def last_json
  last_response.body
end

SimpleCov.start