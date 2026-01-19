require "active_support/core_ext/integer/time"
require "uri"

Rails.application.configure do
  raw_app_host = ENV.fetch("APP_HOST", "b-itconsulting-cfdb3efa88f5.herokuapp.com")
  raw_app_protocol = ENV.fetch("APP_PROTOCOL", "https")
  uri = raw_app_host.include?("://") ? URI.parse(raw_app_host) : URI::Generic.build(scheme: raw_app_protocol, host: raw_app_host)

  config.x.app_host = uri.host
  config.x.app_protocol = uri.scheme || raw_app_protocol
  # Only set app_port if it's a non-standard port; otherwise leave it nil
  config.x.app_port = (uri.port && ![80, 443].include?(uri.port)) ? uri.port : nil

  config.action_mailer.default_url_options = {
    host: config.x.app_host,
    protocol: config.x.app_protocol
  }
  config.action_mailer.default_url_options[:port] = config.x.app_port if config.x.app_port
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/master.key, or an environment
  # key such as config/credentials/production.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from `public/`, relying on NGINX/Apache to do so instead.
  # config.public_file_server.enabled = false

  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Do not fall back to assets pipeline if a precompiled asset is missed.
  config.assets.compile = true

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :cloudinary

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Can be used together with config.force_ssl for Strict-Transport-Security and secure cookies.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Log to STDOUT by default
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # "info" includes generic and useful information about system operation, but avoids logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII). If you
  # want to log everything, set the level to "debug".
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter = :resque
  # config.active_job.queue_name_prefix = "b_itconsulting_production"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
  #
  config.action_mailer.delivery_method = :smtp

  # SMTP settings with timeout configuration
  smtp_port = ENV.fetch("SMTP_PORT", "465").to_i
  config.action_mailer.smtp_settings = {
    address: ENV["SMTP_ADDRESS"],
    port: smtp_port,
    domain: ENV["SMTP_DOMAIN"],
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    authentication: :plain,
    # Port 465 uses implicit SSL/TLS, port 587 uses STARTTLS
    tls: (smtp_port == 465),
    ssl: (smtp_port == 465),
    enable_starttls_auto: (smtp_port == 587),
    open_timeout: 15,
    read_timeout: 15
  }

  config.after_initialize do
    default_url_options = {
      host: Rails.application.config.x.app_host,
      protocol: Rails.application.config.x.app_protocol
    }
    if (port = Rails.application.config.x.app_port)
      default_url_options[:port] = port
    end

    Rails.application.routes.default_url_options.merge!(default_url_options)
    config.action_controller.default_url_options = default_url_options
    ActiveStorage::Current.url_options = default_url_options
  end
end
