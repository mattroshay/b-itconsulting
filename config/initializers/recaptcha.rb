Recaptcha.configure do |config|
  if Rails.env.production?
    # In production, require reCAPTCHA credentials to be set
    # This ensures configuration errors are caught during deployment
    config.site_key = ENV.fetch("RECAPTCHA_SITE_KEY")
    config.secret_key = ENV.fetch("RECAPTCHA_SECRET_KEY")
  else
    # In development/test, allow optional credentials for easier local development
    config.site_key = ENV.fetch("RECAPTCHA_SITE_KEY", nil)
    config.secret_key = ENV.fetch("RECAPTCHA_SECRET_KEY", nil)
  end
end
