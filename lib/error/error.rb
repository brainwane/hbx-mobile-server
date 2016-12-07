module Errors

  def self.included base

    base.error ::SQLite3::Exception do
      $logger.error env['sinatra.error']
      status 400
      {:error => "database error"}.to_json
    end

    base.not_found do
      $logger.error env['sinatra.error']
      status 400
      {:error => "API is not implemented"}.to_json
    end

  end

end