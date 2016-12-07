module HbxMobileServer
  module Configuration

    def self.included base

      # Common configuration - applicable across environments
      base.configure do
        base.set :app_file, File.path("#{base.settings.root}/app.rb")

        file = File.new "#{base.settings.root}/#{base.settings.log_directory}/#{base.settings.environment}.log", 'a+'
        file.sync = true
        base.use Rack::CommonLogger, file
        $logger = Logger.new file
        Database::Migrate::Visit.create_table
      end

      # Configuration related to development environment
      base.configure :development do
        base.disable :show_exceptions
        base.disable :dump_errors
        base.enable :logging, :raise_errors

        $logger.level = Logger::DEBUG
      end

      # Configuration related to test environment
      base.configure :test do
        base.disable :show_exceptions
        base.disable :dump_errors
        base.enable :logging, :dump_errors, :raise_errors

        $logger.level = Logger::DEBUG
      end

      # Configuration related to production environment
      base.configure :production do
        base.set :raise_errors, false
        base.set :show_exceptions, false

        $logger.level = Logger::INFO
      end

    end # def self.included base
  end
end