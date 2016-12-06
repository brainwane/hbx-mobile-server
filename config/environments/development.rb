Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.enroll_url = 'http://mobile.dcmic.org:3000'
  config.mobile_url_home = 'http://mobile.dcmic.org:3000'
  config.mobile_url_login_form = 'http://mobile.dcmic.org:3000/users/sign_in'
  config.mobile_url_login = 'http://mobile.dcmic.org:3000/users/sign_in'

  config.session_id_cookie_domain = 'mobile.dcmic.org'
  config.session_id_cookie_name = '_session_id'

  config.broker_endpoint = 'mobile.dcmic.org:3000/api/v1/mobile_api/employers_list'
  config.employer_details_endpoint = 'mobile.dcmic.org:3000/api/v1/mobile_api/employer_details'
  config.employee_roster_endpoint = 'mobile.dcmic.org:3000/api/v1/mobile_api/employee_roster'
end
