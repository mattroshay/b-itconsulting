# frozen_string_literal: true

# LinkedIn integration settings stored in inheritable options for env overrides.
linkedin_config = Rails.application.config.x.linkedin = ActiveSupport::InheritableOptions.new

allowed_visibilities = %w[PUBLIC CONNECTIONS].freeze
linkedin_config.access_token = ENV["LINKEDIN_ACCESS_TOKEN"]
linkedin_config.author_urn = ENV["LINKEDIN_AUTHOR_URN"]
configured_visibility = ENV.fetch("LINKEDIN_POST_VISIBILITY", "PUBLIC").to_s.upcase
linkedin_config.visibility = allowed_visibilities.include?(configured_visibility) ? configured_visibility : "PUBLIC"
linkedin_config.enabled = linkedin_config.access_token.present? && linkedin_config.author_urn.present?

if !allowed_visibilities.include?(configured_visibility)
  Rails.logger.warn("LinkedIn visibility '#{configured_visibility}' is invalid, defaulting to PUBLIC")
end

ActiveSupport::Notifications.instrument("linkedin.config.initialized") do
  Rails.logger.info("LinkedIn publishing enabled") if linkedin_config.enabled
end
