RACK_ENV ||= ENV['RACK_ENV'] || 'development'

DB = Sequel.connect('sqlite://security.db')
Dir[File.join(File.dirname(__FILE__), '*.rb')].each { |f| require f }