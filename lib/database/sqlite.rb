module Database
  module SQLite

    # Save the object to the database
    def persist object
      if object.save
        $logger.debug "..persisted to SQLite: \n....#{object.inspect}\n"
      else
        raise Database::Error, "#{object.class} could not be saved"
      end
    end

  end
end