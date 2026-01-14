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
    API_VERSION = ENV.fetch("LINKEDIN_API_VERSION", "202411").freeze
    RESTLI_VERSION = "2.0.0"
    DEFAULT_TIMEOUT = 10
    VALID_VISIBILITIES = %w[PUBLIC CONNECTIONS].freeze

    def initialize(config: Rails.application.config.x.linkedin)
      @config = config
    end

    def enabled?
      @config.enabled
    end

    def publish!(title:, article_url:, commentary:, visibility: nil, description: nil)
      raise Linkedin::Error, "LinkedIn integration disabled" unless enabled?

      final_visibility = visibility || @config.visibility
      validate_visibility!(final_visibility)

      payload = build_payload(
        title: title,
        article_url: article_url,
        commentary: commentary,
        visibility: final_visibility,
        description: description
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

    def build_payload(title:, article_url:, commentary:, visibility:, description: nil)
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
          "article" => {
            "source" => article_url,
            "title" => title,
            "description" => description || title
          }
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
  end
end
