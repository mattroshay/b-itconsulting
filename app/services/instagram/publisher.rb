# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Instagram
  class Error < StandardError; end
  class TokenExpiredError < Error; end
  class RateLimitError < Error; end
  class ValidationError < Error; end

  class Publisher
    GRAPH_BASE_URL = ENV.fetch("INSTAGRAM_GRAPH_BASE_URL", "https://graph.facebook.com").freeze
    GRAPH_VERSION = ENV.fetch("INSTAGRAM_GRAPH_API_VERSION", "v20.0").freeze
    DEFAULT_TIMEOUT = 10

    def initialize(config: Rails.application.config.x.instagram)
      @config = config
    end

    def enabled?
      @config.enabled
    end

    def create_container!(caption:, image_url: nil, video_url: nil)
      raise Instagram::Error, "Instagram integration disabled" unless enabled?
      validate_inputs!(caption: caption, image_url: image_url, video_url: video_url)
      create_media_container(caption: caption, image_url: image_url, video_url: video_url)
    end

    def container_status(container_id)
      response = get("/#{container_id}", "fields" => "status_code")
      body = parse_response!(response)
      body["status_code"]
    end

    def publish_container!(container_id)
      params = base_params.merge("creation_id" => container_id)
      response = post("/#{@config.ig_user_id}/media_publish", params)
      body = parse_response!(response)
      body["id"]
    end

    private

    def validate_inputs!(caption:, image_url:, video_url:)
      raise Instagram::Error, "Instagram access token missing" if @config.access_token.blank?
      raise Instagram::Error, "Instagram user id missing" if @config.ig_user_id.blank?
      return if image_url.present? || video_url.present?

      raise Instagram::Error, "Instagram requires an image or video to publish"
    end

    def create_media_container(caption:, image_url:, video_url:)
      params = base_params.merge("caption" => caption)

      if video_url.present?
        params["media_type"] = "VIDEO"
        params["video_url"] = video_url
      else
        params["image_url"] = image_url
      end

      response = post("/#{@config.ig_user_id}/media", params)
      body = parse_response!(response)
      body.fetch("id")
    end

    def base_params
      {
        "access_token" => @config.access_token
      }
    end

    def post(path, params)
      uri = build_uri(path)
      request = Net::HTTP::Post.new(uri)
      request.set_form_data(params)
      perform_request(uri, request)
    end

    def get(path, params)
      uri = build_uri(path, params)
      request = Net::HTTP::Get.new(uri)
      perform_request(uri, request)
    end

    def perform_request(uri, request)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = DEFAULT_TIMEOUT
      http.read_timeout = DEFAULT_TIMEOUT
      http.request(request)
    end

    def build_uri(path, params = {})
      normalized_path = "/#{GRAPH_VERSION}#{path}"
      uri = URI.join(GRAPH_BASE_URL, normalized_path)
      uri.query = URI.encode_www_form(params) if params.present?
      uri
    end

    def parse_response!(response)
      code = response.code.to_i
      body = response.body.presence && JSON.parse(response.body)

      case code
      when 200, 201
        body || {}
      when 400
        error_message = body&.dig("error", "message") || response.body
        raise Instagram::ValidationError, error_message
      when 401, 403
        error_message = body&.dig("error", "message") || response.body
        raise Instagram::TokenExpiredError, error_message
      when 429
        error_message = body&.dig("error", "message") || "Instagram API rate limit exceeded"
        raise Instagram::RateLimitError, error_message
      else
        raise Instagram::Error, "Instagram API #{code}: #{response.body}"
      end
    rescue JSON::ParserError
      raise Instagram::Error, "Instagram API #{response.code}: invalid JSON response"
    end
  end
end
