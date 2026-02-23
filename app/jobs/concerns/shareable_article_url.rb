# frozen_string_literal: true

module ShareableArticleUrl
  extend ActiveSupport::Concern

  private

  def article_url_for(article)
    url_helpers.article_url(article, **app_url_options)
  end

  def url_helpers
    Rails.application.routes.url_helpers
  end

  def app_url_options
    @app_url_options ||= build_app_url_options
  end

  def build_app_url_options
    cfg = Rails.application.config.x
    host = cfg.app_host
    if host.blank?
      if Rails.env.production?
        Rails.logger.error(
          "APP_HOST environment variable is not set; " \
          "cannot generate public article URL for #{self.class.name} in production"
        )
        raise StandardError, "APP_HOST environment variable must be configured in production"
      else
        Rails.logger.warn(
          "APP_HOST environment variable is not set; " \
          "defaulting to example.com for non-production #{self.class.name}"
        )
        host = "example.com"
      end
    end

    protocol = cfg.app_protocol || "https"
    port = cfg.app_port

    options = { host: host, protocol: protocol }
    options[:port] = port.to_i if port.present? && port.to_i.positive?
    options
  end
end
