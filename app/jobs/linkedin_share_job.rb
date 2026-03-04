# frozen_string_literal: true

require "net/http"
require_relative "../services/linkedin/publisher"

class LinkedinShareJob < ApplicationJob
  include Concerns::ShareableArticleUrl

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
    image_url = article_image_url(article)

    publisher.publish!(
      title: article.title,
      article_url: article_url,
      commentary: build_commentary(article, article_url, snippet),
      description: snippet || article.title,
      image_url: image_url
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

  def article_image_url(article)
    # Try to get the first media item (image or video)
    first_media = article.media.first
    return nil unless first_media

    # Check if it's a video - if so, generate a preview image
    if first_media.content_type&.start_with?("video/")
      return video_thumbnail_url(first_media)
    end

    # For images (including GIFs), return the direct URL
    if first_media.content_type&.start_with?("image/")
      return Rails.application.routes.url_helpers.url_for(first_media)
    end

    nil
  rescue StandardError => e
    Rails.logger.warn("Failed to generate image URL for article ##{article.id}: #{e.message}")
    nil
  end

  def video_thumbnail_url(video_attachment)
    # Active Storage can generate video previews automatically if ffmpeg is installed
    # The preview method extracts a frame from the video
    if video_attachment.previewable?
      preview = video_attachment.preview(resize_to_limit: [1200, 627])
      Rails.application.routes.url_helpers.url_for(preview)
    else
      Rails.logger.warn("Video #{video_attachment.id} is not previewable - ffmpeg may not be installed")
      nil
    end
  rescue StandardError => e
    Rails.logger.warn("Failed to generate video thumbnail: #{e.message}")
    nil
  end
end
