# frozen_string_literal: true

require "net/http"
require_relative "../services/instagram/publisher"

class InstagramPollContainerJob < ApplicationJob
  queue_as :default

  class ContainerPendingError < StandardError; end

  discard_on ActiveRecord::RecordNotFound
  retry_on ContainerPendingError, wait: 3.seconds, attempts: 10
  retry_on Net::OpenTimeout, Net::ReadTimeout, Timeout::Error, Errno::ECONNRESET, wait: 10.seconds, attempts: 3

  def perform(article_id, container_id)
    article = Article.find(article_id)
    return Rails.logger.info("Article ##{article_id} already shared on Instagram, skipping") if article.shared_on_instagram?

    config = Rails.application.config.x.instagram
    publisher = Instagram::Publisher.new(config: config)

    status = publisher.container_status(container_id)

    case status
    when "FINISHED"
      media_id = publisher.publish_container!(container_id)
      article.mark_shared_on_instagram!(media_id: media_id)
      Rails.logger.info("Article ##{article_id} successfully shared to Instagram (media #{media_id})")
    when "ERROR"
      raise Instagram::Error, "Instagram media processing failed for container #{container_id}"
    else
      raise ContainerPendingError, "Container #{container_id} not ready yet (status: #{status})"
    end
  rescue Instagram::RateLimitError => e
    Rails.logger.warn("Instagram rate limit reached for article ##{article_id}: #{e.message} (no retry)")
  rescue Instagram::TokenExpiredError => e
    Rails.logger.error("Instagram token expired for article ##{article_id}: #{e.message}")
    raise
  rescue Instagram::Error => e
    Rails.logger.error("Instagram publish failed for article ##{article_id}: #{e.class}: #{e.message}")
    raise
  end
end
