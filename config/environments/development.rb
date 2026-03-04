require "active_support/core_ext/integer/time"
require "uri"

Rails.application.configure do
  raw_app_host = ENV.fetch("APP_HOST", "localhost")
  raw_app_protocol = ENV.fetch("APP_PROTOCOL", "http")
  uri = URI.parse(raw_app_host.include?("://") ? raw_app_host : "#{raw_app_protocol}://#{raw_app_host}")

  config.x.app_host = uri.host
  config.x.app_protocol = uri.scheme || raw_app_protocol
  config.x.app_port = (uri.port && ![80, 443].include?(uri.port)) ? uri.port : nil

  config.action_mailer.default_url_options = { host: config.x.app_host, protocol: config.x.app_protocol }
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :cloudinary

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              ENV.fetch("SMTP_ADDRESS"),
    port:                 ENV.fetch("SMTP_PORT", "465").to_i,
    domain:               ENV.fetch("SMTP_DOMAIN"),
    user_name:            ENV.fetch("SMTP_USERNAME"),
    password:             ENV.fetch("SMTP_PASSWORD"),
    authentication:       :plain,          # try :plain if login fails
    ssl:                  true,            # implicit SSL for port 465
    enable_starttls_auto: false            # STARTTLS is for port 587, not 465
  }

  # This helps with testing mail in development
  config.action_mailer.raise_delivery_errors = true

  config.after_initialize do
    default_url_options = {
      host: Rails.application.config.x.app_host,
      protocol: Rails.application.config.x.app_protocol
    }
    Rails.application.routes.default_url_options.merge!(default_url_options)
    config.action_controller.default_url_options = default_url_options
    ActiveStorage::Current.url_options = default_url_options
  end

end
