# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

module Linkedin
  class PublisherTest < ActiveSupport::TestCase
    setup do
      @linkedin_config = Rails.application.config.x.linkedin
      @original_linkedin_settings = {
        access_token: @linkedin_config.access_token,
        author_urn: @linkedin_config.author_urn,
        visibility: @linkedin_config.visibility,
        enabled: @linkedin_config.enabled
      }

      enable_linkedin_config!
      @publisher = Linkedin::Publisher.new
      WebMock.enable!
    end

    teardown do
      @original_linkedin_settings.each do |attr, value|
        @linkedin_config.public_send("#{attr}=", value)
      end
      WebMock.disable!
    end

    # Test enabled? method
    test "enabled? returns true when LinkedIn is configured" do
      assert @publisher.enabled?
    end

    test "enabled? returns false when LinkedIn is disabled" do
      @linkedin_config.enabled = false
      publisher = Linkedin::Publisher.new

      assert_not publisher.enabled?
    end

    # Test request building (build_payload)
    test "builds correct payload with all required fields" do
      stub_linkedin_api_success

      @publisher.publish!(
        title: "Test Article",
        article_url: "https://example.com/article",
        commentary: "Check out this article!"
      )

      assert_requested :post, "https://api.linkedin.com/rest/posts" do |req|
        body = JSON.parse(req.body)
        body["author"] == "urn:li:person:123456" &&
          body["commentary"] == "Check out this article!" &&
          body["visibility"] == "PUBLIC" &&
          body["lifecycleState"] == "PUBLISHED" &&
          body["content"]["article"]["title"] == "Test Article" &&
          body["content"]["article"]["source"] == "https://example.com/article" &&
          body["content"]["article"]["description"] == "Test Article"
      end
    end

    test "builds payload with custom visibility" do
      stub_linkedin_api_success

      @publisher.publish!(
        title: "Test Article",
        article_url: "https://example.com/article",
        commentary: "Check out this article!",
        visibility: "CONNECTIONS"
      )

      assert_requested :post, "https://api.linkedin.com/rest/posts" do |req|
        body = JSON.parse(req.body)
        body["visibility"] == "CONNECTIONS"
      end
    end

    test "builds payload with custom description" do
      stub_linkedin_api_success

      @publisher.publish!(
        title: "Test Article",
        article_url: "https://example.com/article",
        commentary: "Check out this article!",
        description: "Custom description for the article"
      )

      assert_requested :post, "https://api.linkedin.com/rest/posts" do |req|
        body = JSON.parse(req.body)
        body["content"]["article"]["description"] == "Custom description for the article"
      end
    end

    test "includes correct headers in request" do
      stub_linkedin_api_success

      @publisher.publish!(
        title: "Test Article",
        article_url: "https://example.com/article",
        commentary: "Check out this article!"
      )

      assert_requested :post, "https://api.linkedin.com/rest/posts" do |req|
        req.headers["Authorization"] == "Bearer test_token" &&
          req.headers["Content-Type"] == "application/json" &&
          req.headers["Linkedin-Version"] == ENV.fetch("LINKEDIN_API_VERSION", "202411") &&
          req.headers["X-Restli-Protocol-Version"] == "2.0.0"
      end
    end

    # Test API response parsing
    test "successfully parses 201 Created response" do
      stub_request(:post, "https://api.linkedin.com/rest/posts")
        .to_return(status: 201, body: { id: "post123" }.to_json, headers: { "Content-Type" => "application/json" })

      response = @publisher.publish!(
        title: "Test Article",
        article_url: "https://example.com/article",
        commentary: "Check out this article!"
      )

      assert_equal "201", response.code
    end

    test "successfully parses 200 OK response" do
      stub_request(:post, "https://api.linkedin.com/rest/posts")
        .to_return(status: 200, body: { id: "post123" }.to_json, headers: { "Content-Type" => "application/json" })

      response = @publisher.publish!(
        title: "Test Article",
        article_url: "https://example.com/article",
        commentary: "Check out this article!"
      )

      assert_equal "200", response.code
    end

    # Test error handling
    test "raises TokenExpiredError on 401 response" do
      stub_request(:post, "https://api.linkedin.com/rest/posts")
        .to_return(status: 401, body: "Unauthorized")

      error = assert_raises(Linkedin::TokenExpiredError) do
        @publisher.publish!(
          title: "Test Article",
          article_url: "https://example.com/article",
          commentary: "Check out this article!"
        )
      end

      assert_equal "LinkedIn access token expired or invalid", error.message
    end

    test "raises RateLimitError on 429 response" do
      stub_request(:post, "https://api.linkedin.com/rest/posts")
        .to_return(status: 429, body: "Too Many Requests")

      error = assert_raises(Linkedin::RateLimitError) do
        @publisher.publish!(
          title: "Test Article",
          article_url: "https://example.com/article",
          commentary: "Check out this article!"
        )
      end

      assert_equal "LinkedIn API rate limit exceeded", error.message
    end

    test "raises generic Error on 400 response" do
      stub_request(:post, "https://api.linkedin.com/rest/posts")
        .to_return(status: 400, body: "Bad Request")

      error = assert_raises(Linkedin::Error) do
        @publisher.publish!(
          title: "Test Article",
          article_url: "https://example.com/article",
          commentary: "Check out this article!"
        )
      end

      assert_match(/LinkedIn API 400/, error.message)
      assert_match(/Bad Request/, error.message)
    end

    test "raises generic Error on 500 response" do
      stub_request(:post, "https://api.linkedin.com/rest/posts")
        .to_return(status: 500, body: "Internal Server Error")

      error = assert_raises(Linkedin::Error) do
        @publisher.publish!(
          title: "Test Article",
          article_url: "https://example.com/article",
          commentary: "Check out this article!"
        )
      end

      assert_match(/LinkedIn API 500/, error.message)
    end

    test "truncates long error messages to 500 characters" do
      long_error = "A" * 600
      stub_request(:post, "https://api.linkedin.com/rest/posts")
        .to_return(status: 400, body: long_error)

      error = assert_raises(Linkedin::Error) do
        @publisher.publish!(
          title: "Test Article",
          article_url: "https://example.com/article",
          commentary: "Check out this article!"
        )
      end

      # Error message should not contain the full 600 character error
      assert error.message.length < 600
      assert_match(/LinkedIn API 400/, error.message)
    end

    test "raises Error when integration is disabled" do
      @linkedin_config.enabled = false
      publisher = Linkedin::Publisher.new

      error = assert_raises(Linkedin::Error) do
        publisher.publish!(
          title: "Test Article",
          article_url: "https://example.com/article",
          commentary: "Check out this article!"
        )
      end

      assert_equal "LinkedIn integration disabled", error.message
      assert_not_requested :post, "https://api.linkedin.com/rest/posts"
    end

    test "handles network timeouts" do
      stub_request(:post, "https://api.linkedin.com/rest/posts")
        .to_timeout

      assert_raises(Net::OpenTimeout, Net::ReadTimeout) do
        @publisher.publish!(
          title: "Test Article",
          article_url: "https://example.com/article",
          commentary: "Check out this article!"
        )
      end
    end

    private

    def enable_linkedin_config!
      @linkedin_config.access_token = "test_token"
      @linkedin_config.author_urn = "urn:li:person:123456"
      @linkedin_config.visibility = "PUBLIC"
      @linkedin_config.enabled = true
    end

    def stub_linkedin_api_success
      stub_request(:post, "https://api.linkedin.com/rest/posts")
        .to_return(status: 201, body: {}.to_json, headers: { "Content-Type" => "application/json" })
    end
  end
end
