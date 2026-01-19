# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Linkedin
  class Error < StandardError; end
  class TokenExpiredError < Error; end
  class RateLimitError < Error; end

  class Publisher
    API_ENDPOINT = URI("https://api.linkedin.com/rest/posts")
    IMAGES_ENDPOINT = URI("https://api.linkedin.com/rest/images")
    API_VERSION = ENV.fetch("LINKEDIN_API_VERSION", "202601").freeze
    RESTLI_VERSION = "2.0.0"
    DEFAULT_TIMEOUT = 10
    VALID_VISIBILITIES = %w[PUBLIC CONNECTIONS].freeze

    def initialize(config: Rails.application.config.x.linkedin)
      @config = config
    end

    def enabled?
      @config.enabled
    end

    def publish!(title:, article_url:, commentary:, visibility: nil, description: nil, image_url: nil)
      raise Linkedin::Error, "LinkedIn integration disabled" unless enabled?

      final_visibility = visibility || @config.visibility
      validate_visibility!(final_visibility)

      # Upload image if provided and get the image URN
      image_urn = nil
      if image_url.present?
        image_urn = upload_image(image_url)
      end

      payload = build_payload(
        title: title,
        article_url: article_url,
        commentary: commentary,
        visibility: final_visibility,
        description: description,
        image_urn: image_urn
      )

      response = perform_request(payload)

      case response.code.to_i
      when 201, 200
        response
      when 401
        raise Linkedin::TokenExpiredError, "LinkedIn access token expired or invalid"
      when 429
        raise Linkedin::RateLimitError, "LinkedIn API rate limit exceeded"
      else
        raise Linkedin::Error, "LinkedIn API #{response.code}: #{response.body.to_s[0, 500]}"
      end
    end

    private

    def validate_visibility!(visibility)
      return if VALID_VISIBILITIES.include?(visibility)

      raise Linkedin::Error,
            "Invalid visibility '#{visibility}'. Must be one of: #{VALID_VISIBILITIES.join(', ')}"
    end

    def build_payload(title:, article_url:, commentary:, visibility:, description: nil, image_urn: nil)
      article_content = {
        "source" => article_url,
        "title" => title,
        "description" => description || title
      }

      # Add thumbnail if image URN is provided
      article_content["thumbnail"] = image_urn if image_urn.present?

      {
        "author" => @config.author_urn,
        "commentary" => commentary,
        "visibility" => visibility,
        "lifecycleState" => "PUBLISHED",
        "distribution" => {
          "feedDistribution" => "MAIN_FEED",
          "targetEntities" => [],
          "thirdPartyDistributionChannels" => []
        },
        "isReshareDisabledByAuthor" => false,
        "content" => {
          "article" => article_content
        }
      }
    end

    def validate_access_token!(token)
      token = token.to_s

      if token.length < 20
        raise Linkedin::Error, "LinkedIn access token appears to be malformed or too short"
      end

      # Require only visible, non-whitespace ASCII characters (no spaces or control chars)
      unless token.match?(/\A[[:graph:]]+\z/)
        raise Linkedin::Error, "LinkedIn access token contains invalid characters or whitespace"
      end
    end

    def perform_request(payload)
      access_token = @config.access_token.to_s
      validate_access_token!(access_token)

      http = Net::HTTP.new(API_ENDPOINT.host, API_ENDPOINT.port)
      http.use_ssl = true
      http.open_timeout = DEFAULT_TIMEOUT
      http.read_timeout = DEFAULT_TIMEOUT

      request = Net::HTTP::Post.new(API_ENDPOINT)
      request["Authorization"] = "Bearer #{access_token}"
      request["Content-Type"] = "application/json"
      request["LinkedIn-Version"] = API_VERSION
      request["X-Restli-Protocol-Version"] = RESTLI_VERSION
      request.body = JSON.dump(payload)

      http.request(request)
    end

    def upload_image(image_url)
      # Step 1: Initialize the upload
      upload_info = initialize_image_upload

      # Step 2: Download the image from the URL
      image_data = download_image(image_url)

      # Step 3: Upload the image to LinkedIn
      upload_image_data(upload_info["uploadUrl"], image_data)

      # Return the image URN
      upload_info["image"]
    rescue StandardError => e
      Rails.logger.error("Failed to upload image to LinkedIn: #{e.message}")
      raise Linkedin::Error, "Image upload failed: #{e.message}"
    end

    def initialize_image_upload
      access_token = @config.access_token.to_s
      validate_access_token!(access_token)

      endpoint = URI("#{IMAGES_ENDPOINT}?action=initializeUpload")
      http = Net::HTTP.new(endpoint.host, endpoint.port)
      http.use_ssl = true
      http.open_timeout = DEFAULT_TIMEOUT
      http.read_timeout = DEFAULT_TIMEOUT

      request = Net::HTTP::Post.new(endpoint)
      request["Authorization"] = "Bearer #{access_token}"
      request["Content-Type"] = "application/json"
      request["LinkedIn-Version"] = API_VERSION
      request["X-Restli-Protocol-Version"] = RESTLI_VERSION

      payload = {
        "initializeUploadRequest" => {
          "owner" => @config.author_urn
        }
      }
      request.body = JSON.dump(payload)

      response = http.request(request)

      unless response.code.to_i == 200
        raise Linkedin::Error, "Image initialization failed: #{response.code} #{response.body}"
      end

      data = JSON.parse(response.body)
      data["value"]
    end

    def download_image(image_url)
      uri = URI(image_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = DEFAULT_TIMEOUT
      http.read_timeout = DEFAULT_TIMEOUT

      response = http.get(uri.request_uri)

      unless response.code.to_i == 200
        raise Linkedin::Error, "Failed to download image from #{image_url}: #{response.code}"
      end

      response.body
    end

    def upload_image_data(upload_url, image_data)
      uri = URI(upload_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = DEFAULT_TIMEOUT
      http.read_timeout = DEFAULT_TIMEOUT

      request = Net::HTTP::Put.new(uri.request_uri)
      request.body = image_data
      request["Content-Type"] = "application/octet-stream"

      response = http.request(request)

      unless [200, 201].include?(response.code.to_i)
        raise Linkedin::Error, "Failed to upload image data: #{response.code} #{response.body}"
      end

      response
    end
  end
end
