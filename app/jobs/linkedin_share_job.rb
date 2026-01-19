# frozen_string_literal: true

require "net/http"
require_relative "../services/linkedin/publisher"

class LinkedinShareJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound
  retry_on Net::OpenTimeout, Net::ReadTimeout, Timeout::Error, Errno::ECONNRESET, wait: 10.seconds, attempts: 3

  def perform(article_id)
    config = Rails.application.config.x.linkedin
    return unless config.enabled

    article = Article.find(article_id)

    # Skip if already shared to LinkedIn
    if article.shared_on_linkedin?
      Rails.logger.info("Article ##{article.id} already shared to LinkedIn at #{article.linkedin_shared_at}")
      return
    end

    article_url = article_url_for(article)
    publisher = Linkedin::Publisher.new(config: config)

    snippet = extract_snippet(article)

    publisher.publish!(
      title: article.title,
      article_url: article_url,
      commentary: build_commentary(article, article_url, snippet),
      description: snippet || article.title
    )

    # Mark as shared on success
    article.mark_shared_on_linkedin!
    Rails.logger.info("Article ##{article.id} successfully shared to LinkedIn")
  rescue Linkedin::RateLimitError => e
    # We intentionally do not retry rate limit errors here to avoid breaching LinkedIn API quotas.
    # Monitoring for this log message should be used to tune job volume and scheduling if needed.
    Rails.logger.warn("LinkedIn rate limit reached for article ##{article_id}: #{e.message} (no retry)")
  rescue Linkedin::Error => e
    Rails.logger.error("LinkedIn publish failed for article ##{article_id}: #{e.class}: #{e.message}")
    raise
  rescue StandardError => e
    Rails.logger.error("LinkedIn publish error for article ##{article_id}: #{e.class}: #{e.message}")
    raise
  end

  private

  def build_commentary(article, article_url, snippet)
    [article.title, snippet.presence, article_url].compact.join("\n\n")
  end

  def extract_snippet(article)
    text = article.rich_content&.to_plain_text.to_s
    cleaned = text.gsub(/\s+/, " ").strip
    return nil if cleaned.blank?

    limit = 300
    cleaned.length > limit ? "#{cleaned[0, limit].rstrip}…" : cleaned
  end

  def article_url_for(article)
    helpers = Rails.application.routes.url_helpers

    fallback_host = ENV["APP_HOST"]
    if fallback_host.blank?
      if Rails.env.production?
        Rails.logger.error("APP_HOST environment variable is not set; cannot generate public article URL for LinkedIn sharing in production")
        raise StandardError, "APP_HOST environment variable must be configured in production"
      else
        Rails.logger.warn("APP_HOST environment variable is not set; defaulting to example.com for non-production article URL generation")
        fallback_host = "example.com"
      end
    end
    fallback_protocol = ENV["APP_PROTOCOL"] || "https"
    fallback_port = ENV["APP_PORT"]

    # Build options explicitly to avoid inheriting problematic :port from global defaults
    url_options = {
      host: fallback_host,
      protocol: fallback_protocol
    }
    # Only add port if explicitly set and non-standard
    url_options[:port] = fallback_port.to_i if fallback_port.present? && fallback_port.to_i > 0

    helpers.article_url(article, **url_options)
  end
end
