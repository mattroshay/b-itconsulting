# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

module Instagram
  class PublisherTest < ActiveSupport::TestCase
    GRAPH_BASE = "https://graph.facebook.com/v20.0".freeze

    setup do
      @instagram_config = Rails.application.config.x.instagram
      @original_instagram_settings = {
        access_token: @instagram_config.access_token,
        ig_user_id: @instagram_config.ig_user_id,
        enabled: @instagram_config.enabled
      }

      enable_instagram_config!
      @publisher = Instagram::Publisher.new
      WebMock.enable!
    end

    teardown do
      @original_instagram_settings.each do |attr, value|
        @instagram_config.public_send("#{attr}=", value)
      end
      WebMock.disable!
    end

    # Test enabled? method
    test "enabled? returns true when Instagram is configured" do
      assert @publisher.enabled?
    end

    test "enabled? returns false when Instagram is disabled" do
      @instagram_config.enabled = false
      publisher = Instagram::Publisher.new

      assert_not publisher.enabled?
    end

    # Test create_container! method
    test "create_container! sends correct params for image post" do
      stub_create_container_success

      @publisher.create_container!(caption: "Hello world", image_url: "https://example.com/img.jpg")

      assert_requested :post, "#{GRAPH_BASE}/#{@instagram_config.ig_user_id}/media" do |req|
        params = URI.decode_www_form(req.body).to_h
        params["caption"] == "Hello world" &&
          params["image_url"] == "https://example.com/img.jpg" &&
          params["access_token"] == "test_token_abc"
      end
    end

    test "create_container! sends correct params for video post" do
      stub_create_container_success

      @publisher.create_container!(caption: "A video", video_url: "https://example.com/vid.mp4")

      assert_requested :post, "#{GRAPH_BASE}/#{@instagram_config.ig_user_id}/media" do |req|
        params = URI.decode_www_form(req.body).to_h
        params["media_type"] == "VIDEO" &&
          params["video_url"] == "https://example.com/vid.mp4"
      end
    end

    test "create_container! returns container id on success" do
      stub_create_container_success

      container_id = @publisher.create_container!(caption: "Hello", image_url: "https://example.com/img.jpg")

      assert_equal "container_123", container_id
    end

    test "create_container! raises Error when integration is disabled" do
      @instagram_config.enabled = false
      publisher = Instagram::Publisher.new

      error = assert_raises(Instagram::Error) do
        publisher.create_container!(caption: "Hello", image_url: "https://example.com/img.jpg")
      end

      assert_equal "Instagram integration disabled", error.message
    end

    test "create_container! raises Error when access_token is missing" do
      @instagram_config.access_token = nil

      error = assert_raises(Instagram::Error) do
        @publisher.create_container!(caption: "Hello", image_url: "https://example.com/img.jpg")
      end

      assert_equal "Instagram access token missing", error.message
    end

    test "create_container! raises Error when ig_user_id is missing" do
      @instagram_config.ig_user_id = nil

      error = assert_raises(Instagram::Error) do
        @publisher.create_container!(caption: "Hello", image_url: "https://example.com/img.jpg")
      end

      assert_equal "Instagram user id missing", error.message
    end

    test "create_container! raises Error when neither image_url nor video_url provided" do
      error = assert_raises(Instagram::Error) do
        @publisher.create_container!(caption: "Hello")
      end

      assert_equal "Instagram requires an image or video to publish", error.message
    end

    # Test container_status method
    test "container_status returns status_code from API" do
      container_id = "container_456"
      stub_request(:get, "#{GRAPH_BASE}/#{container_id}")
        .with(query: hash_including("fields" => "status_code", "access_token" => "test_token_abc"))
        .to_return(status: 200, body: { "status_code" => "FINISHED" }.to_json,
                   headers: { "Content-Type" => "application/json" })

      status = @publisher.container_status(container_id)

      assert_equal "FINISHED", status
    end

    test "container_status raises Error when integration is disabled" do
      @instagram_config.enabled = false
      publisher = Instagram::Publisher.new

      error = assert_raises(Instagram::Error) do
        publisher.container_status("container_456")
      end

      assert_equal "Instagram integration disabled", error.message
    end

    test "container_status raises Error when access_token is missing" do
      @instagram_config.access_token = nil

      error = assert_raises(Instagram::Error) do
        @publisher.container_status("container_456")
      end

      assert_equal "Instagram access token missing", error.message
    end

    # Test publish_container! method
    test "publish_container! sends correct params" do
      container_id = "container_123"
      stub_request(:post, "#{GRAPH_BASE}/#{@instagram_config.ig_user_id}/media_publish")
        .to_return(status: 200, body: { "id" => "post_789" }.to_json,
                   headers: { "Content-Type" => "application/json" })

      @publisher.publish_container!(container_id)

      assert_requested :post, "#{GRAPH_BASE}/#{@instagram_config.ig_user_id}/media_publish" do |req|
        params = URI.decode_www_form(req.body).to_h
        params["creation_id"] == container_id &&
          params["access_token"] == "test_token_abc"
      end
    end

    test "publish_container! returns post id on success" do
      stub_request(:post, "#{GRAPH_BASE}/#{@instagram_config.ig_user_id}/media_publish")
        .to_return(status: 200, body: { "id" => "post_789" }.to_json,
                   headers: { "Content-Type" => "application/json" })

      post_id = @publisher.publish_container!("container_123")

      assert_equal "post_789", post_id
    end

    # Test error handling in parse_response!
    test "raises ValidationError on 400 response" do
      stub_create_container_error(400, { "error" => { "message" => "Invalid parameter" } }.to_json)

      error = assert_raises(Instagram::ValidationError) do
        @publisher.create_container!(caption: "Hello", image_url: "https://example.com/img.jpg")
      end

      assert_equal "Invalid parameter", error.message
    end

    test "raises TokenExpiredError on 401 response" do
      stub_create_container_error(401, { "error" => { "message" => "Invalid OAuth access token" } }.to_json)

      error = assert_raises(Instagram::TokenExpiredError) do
        @publisher.create_container!(caption: "Hello", image_url: "https://example.com/img.jpg")
      end

      assert_equal "Invalid OAuth access token", error.message
    end

    test "raises TokenExpiredError on 403 response" do
      stub_create_container_error(403, { "error" => { "message" => "Permissions error" } }.to_json)

      error = assert_raises(Instagram::TokenExpiredError) do
        @publisher.create_container!(caption: "Hello", image_url: "https://example.com/img.jpg")
      end

      assert_equal "Permissions error", error.message
    end

    test "raises RateLimitError on 429 response" do
      stub_create_container_error(429, { "error" => { "message" => "Rate limit reached" } }.to_json)

      error = assert_raises(Instagram::RateLimitError) do
        @publisher.create_container!(caption: "Hello", image_url: "https://example.com/img.jpg")
      end

      assert_equal "Rate limit reached", error.message
    end

    test "raises RateLimitError on 429 response with fallback message when no error body" do
      stub_create_container_error(429, "Too Many Requests")

      error = assert_raises(Instagram::RateLimitError) do
        @publisher.create_container!(caption: "Hello", image_url: "https://example.com/img.jpg")
      end

      assert_equal "Instagram API rate limit exceeded", error.message
    end

    test "raises generic Error on 500 response" do
      stub_create_container_error(500, "Internal Server Error")

      error = assert_raises(Instagram::Error) do
        @publisher.create_container!(caption: "Hello", image_url: "https://example.com/img.jpg")
      end

      assert_match(/Instagram API 500/, error.message)
    end

    test "raises Error on invalid JSON response" do
      stub_create_container_error(401, "not valid json {{")

      error = assert_raises(Instagram::Error) do
        @publisher.create_container!(caption: "Hello", image_url: "https://example.com/img.jpg")
      end

      assert_match(/invalid JSON response/, error.message)
    end

    # Test timeout handling
    test "handles connection timeout" do
      stub_request(:post, "#{GRAPH_BASE}/#{@instagram_config.ig_user_id}/media")
        .to_timeout

      assert_raises(Net::OpenTimeout) do
        @publisher.create_container!(caption: "Hello", image_url: "https://example.com/img.jpg")
      end
    end

    test "handles read timeout" do
      stub_request(:post, "#{GRAPH_BASE}/#{@instagram_config.ig_user_id}/media")
        .to_raise(Net::ReadTimeout)

      assert_raises(Net::ReadTimeout) do
        @publisher.create_container!(caption: "Hello", image_url: "https://example.com/img.jpg")
      end
    end

    private

    def enable_instagram_config!
      @instagram_config.access_token = "test_token_abc"
      @instagram_config.ig_user_id = "ig_user_999"
      @instagram_config.enabled = true
    end

    def stub_create_container_success
      stub_request(:post, "#{GRAPH_BASE}/#{@instagram_config.ig_user_id}/media")
        .to_return(status: 200, body: { "id" => "container_123" }.to_json,
                   headers: { "Content-Type" => "application/json" })
    end

    def stub_create_container_error(status, body)
      stub_request(:post, "#{GRAPH_BASE}/#{@instagram_config.ig_user_id}/media")
        .to_return(status: status, body: body, headers: { "Content-Type" => "application/json" })
    end
  end
end
