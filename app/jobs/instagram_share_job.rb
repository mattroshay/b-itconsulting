# frozen_string_literal: true

require "net/http"
require_relative "../services/instagram/publisher"

class InstagramShareJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound
  retry_on Net::OpenTimeout, Net::ReadTimeout, Timeout::Error, Errno::ECONNRESET, wait: 10.seconds, attempts: 3

  def perform(article_id)
    config = Rails.application.config.x.instagram
    return unless config.enabled

    article = Article.find(article_id)
    if article.shared_on_instagram?
      Rails.logger.info("Article ##{article.id} already shared to Instagram at #{article.instagram_shared_at}")
      return
    end

    media_payload = primary_media_payload(article)
    unless media_payload
      Rails.logger.warn("Instagram share skipped for article ##{article.id}: no suitable media attachment found")
      return
    end

    caption = build_caption(article)
    publisher = Instagram::Publisher.new(config: config)

    media_id = publisher.publish!(
      caption: caption,
      image_url: media_payload[:image_url],
      video_url: media_payload[:video_url]
    )

    article.mark_shared_on_instagram!(media_id: media_id)
    Rails.logger.info("Article ##{article.id} successfully shared to Instagram (media #{media_id})")
  rescue Instagram::RateLimitError => e
    Rails.logger.warn("Instagram rate limit reached for article ##{article_id}: #{e.message} (no retry)")
  rescue Instagram::TokenExpiredError => e
    Rails.logger.error("Instagram token expired for article ##{article_id}: #{e.message}")
    raise
  rescue Instagram::Error => e
    Rails.logger.error("Instagram publish failed for article ##{article_id}: #{e.class}: #{e.message}")
    raise
  rescue StandardError => e
    Rails.logger.error("Instagram publish error for article ##{article_id}: #{e.class}: #{e.message}")
    raise
  end

  private

  def build_caption(article)
    snippet = extract_snippet(article)
    url = article_url_for(article)
    fragments = [article.title, snippet, url, hashtags_fragment].compact
    fragments.join("\n\n").strip
  end

  def hashtags_fragment
    tags = Array(Rails.application.config.x.instagram.default_hashtags)
    return if tags.blank?

    tags.map { |tag| tag.start_with?("#") ? tag : "##{tag}" }.join(" ")
  end

  def extract_snippet(article)
    text = article.rich_content&.to_plain_text.to_s
    cleaned = text.gsub(/\s+/, " ").strip
    return nil if cleaned.blank?

    limit = 300
    cleaned.length > limit ? "#{cleaned[0, limit].rstrip}…" : cleaned
  end

  def primary_media_payload(article)
    attachment = article.media.first || article.images.first
    return nil unless attachment

    if attachment.content_type&.start_with?("video/")
      { video_url: blob_url_for(attachment) }
    elsif attachment.content_type&.start_with?("image/")
      { image_url: blob_url_for(attachment) }
    else
      nil
    end
  rescue StandardError => e
    Rails.logger.warn("Failed to generate media URL for article ##{article.id}: #{e.message}")
    nil
  end

  def article_url_for(article)
    url_helpers.article_url(article, **default_url_options)
  end

  def blob_url_for(attachment)
    url_helpers.rails_blob_url(attachment, **default_url_options)
  end

  def url_helpers
    Rails.application.routes.url_helpers
  end

  def default_url_options
    host = ENV["APP_HOST"]
    if host.blank?
      if Rails.env.production?
        Rails.logger.error("APP_HOST environment variable is not set; cannot generate public article URL for Instagram sharing in production")
        raise StandardError, "APP_HOST environment variable must be configured in production"
      else
        Rails.logger.warn("APP_HOST environment variable is not set; defaulting to example.com for non-production Instagram sharing")
        host = "example.com"
      end
    end

    protocol = ENV["APP_PROTOCOL"] || "https"
    port = ENV["APP_PORT"]

    options = { host: host, protocol: protocol }
    options[:port] = port.to_i if port.present? && port.to_i.positive?
    options
  end
end
