Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure static file server for tests with Cache-Control for performance.
  config.serve_static_files   = true
  config.static_cache_control = 'public, max-age=3600'

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Randomize the order test cases are executed.
  config.active_support.test_order = :random

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.enroll_url = 'https://enroll-mobile.dchbx.org'
  config.mobile_url_home = 'https://www.dchealthlink.com'
  config.mobile_url_iam_login_form = 'https://www.dchealthlink.com/login-sso'
  config.mobile_url_iam_login = 'https://app.dchealthlink.com/oaam_server/loginAuth.do'
  config.mobile_url_iam_login_auth_jump = 'https://app.dchealthlink.com/oaam_server/authJump.do?jump=false'
  config.mobile_url_iam_challenge_user = 'https://app.dchealthlink.com/oaam_server/challengeUser.do'

  config.session_id_cookie_domain = 'enroll-mobile.dchbx.org'
  config.session_id_cookie_name = '_session_id'
  
  #to use production IAM with a test enroll instance, override where the SAML is posted to  
  config.override_saml_enroll_url = 'enroll-mobile.dchbx.org'

  config.broker_endpoint = 'https://enroll-mobile.dchbx.org/api/v1/mobile_api/employers_list'
  config.employer_details_endpoint = 'https://enroll-mobile.dchbx.org/api/v1/mobile_api/employer_details'
  config.employee_roster_endpoint = 'https://enroll-mobile.dchbx.org/api/v1/mobile_api/employee_roster'


end
