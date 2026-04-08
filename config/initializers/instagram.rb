# frozen_string_literal: true

# Instagram integration settings are stored here so environments can override them.
instagram_config = Rails.application.config.x.instagram = ActiveSupport::InheritableOptions.new

instagram_config.access_token = ENV["INSTAGRAM_ACCESS_TOKEN"]
instagram_config.ig_user_id = ENV["INSTAGRAM_IG_USER_ID"]
instagram_config.page_id = ENV["INSTAGRAM_PAGE_ID"]
instagram_config.default_hashtags =
  ENV["INSTAGRAM_DEFAULT_HASHTAGS"]
    .to_s
    .split(",")
    .map { |tag| tag.strip.delete_prefix("#") }
    .reject(&:blank?)
instagram_config.enabled =
  instagram_config.access_token.present? &&
  instagram_config.ig_user_id.present??

unless instagram_config.enabled
  Rails.logger.info("Instagram publishing disabled (missing credentials)")
else
  Rails.logger.info("Instagram publishing enabled")
end
