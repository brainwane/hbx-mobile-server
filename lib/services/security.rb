module Services
  class Security
    HTTP_ERROR_CODE = 400
    FORM_BHAROSA_DATA_FIELD = :Bharosa_Challenge_PadDataField

    def initialize settings, params
      @settings = settings
      @params = params
    end

    def authenticate
      begin
        email, password, device_id = @params.values_at :userid, :pass, :device_id
        security_question, cookies, hidden_values = post_credentials email, password
        raise HbxException.new(message: 'Not authorized', code: 401) unless security_question

        visit = Database::Model::Visit.create_visit(cookies, device_id, email, hidden_values)
        yield security_question, visit
      end
    rescue Errors::HbxException => e
      $logger.error e.message
      error = {message: e.message, status: e.code}
    rescue Exception => e
      $logger.error e.message
      e.backtrace.each { |x| $logger.error x }
      error = {message: 'Unable to contact security server', status: 500}
    ensure
      yield security_question, visit, error
    end

    def security_answer
      begin
        visit = Database::Model::Visit.find(id: @params[:id])
        raise 'Corresponding visit not found, erroneous request' unless visit

        mechanize = ::Mechanize.new
        mechanize.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        reader = StringIO.new visit['cookies'], 'r'
        mechanize.cookie_jar.load reader
        security_answer_form_submit mechanize, visit

        session_id = cookie_value mechanize.cookies, @settings.security.session_id_cookie_name, @settings.security.session_id_cookie_domain
        yield session_id, enroll_url, broker_endpoint, employer_details_endpoint, employee_roster_endpoint
      rescue Exception => e
        $logger.error e.message
        e.backtrace.each { |x| $logger.error x }
      end
    end

    #
    # Private
    #
    private

    def post_credentials email, password
      begin
        mechanize = ::Mechanize.new
        mechanize.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        response = authenticate_user mechanize, email, password
        html_entities = ::HTMLEntities.new
        body = response.body
        validate_submission body

        string_stream = StringIO.new
        mechanize.cookie_jar.save string_stream, session: true
        authentication_response body, html_entities, string_stream
      rescue Exception => e
        $logger.error e.message
      end
    end

    def authenticate_user mechanize, email, password
      response = mechanize.get @settings.security['mobile_url_home']
      raise 'Could not access the home page' if response.code.to_i >= HTTP_ERROR_CODE

      response = mechanize.get @settings.security['mobile_url_iam_login_form']
      raise 'Could not access the login page' if response.code.to_i >= HTTP_ERROR_CODE

      form_values = {:clientOffset => -4, :userid => email, :pass => password}
      response = mechanize.post @settings.security['mobile_url_iam_login'], form_values
      raise 'Could not login' if response.code.to_i >= HTTP_ERROR_CODE

      #sleep 3.0 #TODO(krish): Why is this needed?
      response = mechanize.get @settings.security['mobile_url_iam_login_auth_jump']
      raise "Error getting IAM login auth jump: #{response.code}" if response.code.to_i >= HTTP_ERROR_CODE
      response
    end

    def security_answer_form_submit mechanize, visit
      form = security_answer_response(mechanize, visit).forms.first

      # To use production IAM with a test enroll instance, override where the SAML is posted to
      if @settings.security['override_saml_enroll_url']
        form.action = form.action.gsub 'enroll.dchealthlink.com', @settings.security['override_saml_enroll_url']
        form.RelayState = form.RelayState.gsub 'enroll.dchealthlink.com', @settings.security['override_saml_enroll_url']
      end
      form.submit
    end

    def security_answer_response mechanize, visit
      mechanize.redirect_ok = false
      response = mechanize.post @settings.security['mobile_url_iam_challenge_user'], security_answer_form_values(visit)
      response_code = response.code.to_i
      response = mechanize.get(response.response['location']) while response_code >= 300 && response_code < 400
      mechanize.redirect_ok = true
      response
    end

    def security_answer_form_values visit
      form_values = {:register => 'Continue', FORM_BHAROSA_DATA_FIELD: @params[:security_answer]}
      JSON.parse(visit[:hidden_fields]).each { |key, value| form_values[key] = value }
      form_values
    end

    # Check to see if we successfully submitted username & password...
    def validate_submission body
      error_matches = body.include?("<label for=\"userid\">Username<\/label>")
      raise "login failed" if error_matches
    end

    def authentication_response body, html_entities, string_stream
      [req.parser.xpath("//div[@class='text-center width-100']").text.strip, # Security Question
       string_stream.string,
       hidden_values(body, html_entities)]
    end

    def hidden_values body, html_entities
      show_view_value = /<input\s+type=\"hidden\"\s+name=\"showView\"\s+value=\"([^"]*)\"/.match(body)
      fk = /<input type="hidden" name="fk" value="([^"]*)"/.match(body)
      {:fk => html_entities.decode(fk[1]), :showView => html_entities.decode(show_view_value[1])}.to_json
    end

    def cookie_value cookies, name, domain
      cookie = cookies.find { |c| c.domain == domain && c.name == name }
      cookie.value if cookie
    end

  end
end