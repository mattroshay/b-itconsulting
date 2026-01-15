# frozen_string_literal: true

require "securerandom"
require "test_helper"
require "webmock/minitest"

class LinkedinShareJobTest < ActiveJob::TestCase
  setup do
    @linkedin_config = Rails.application.config.x.linkedin
    @original_linkedin_settings = {
      access_token: @linkedin_config.access_token,
      author_urn: @linkedin_config.author_urn,
      visibility: @linkedin_config.visibility,
      enabled: @linkedin_config.enabled
    }

    enable_linkedin_config!
    WebMock.enable!
  end

  teardown do
    @original_linkedin_settings.each do |attr, value|
      @linkedin_config.public_send("#{attr}=", value)
    end
    clear_enqueued_jobs
    clear_performed_jobs
    WebMock.disable!
  end

  test "successfully shares article to LinkedIn" do
    article = create_article!

    stub_linkedin_api_success

    LinkedinShareJob.perform_now(article.id)

    assert article.reload.shared_on_linkedin?, "Article should be marked as shared"
    assert_requested :post, "https://api.linkedin.com/rest/posts"
  end

  test "raises LinkedIn errors after logging them" do
    article = create_article!

    stub_linkedin_api_error(code: 400, body: "Bad Request")

    assert_raises(Linkedin::Error) { LinkedinShareJob.perform_now(article.id) }

    # Article should not be marked as shared if error occurred
    assert_not article.reload.shared_on_linkedin?
  end

  test "handles token expiration" do
    article = create_article!

    stub_linkedin_api_error(code: 401, body: "Unauthorized")

    assert_raises(Linkedin::TokenExpiredError) do
      LinkedinShareJob.perform_now(article.id)
    end
  end

  test "retries on transient network errors" do
    article = create_article!

    # First attempt: timeout
    # Second attempt: success
    stub_request(:post, "https://api.linkedin.com/rest/posts")
      .to_timeout.then
      .to_return(status: 201, body: {}.to_json)

    assert_performed_jobs 2 do
      perform_enqueued_jobs do
        LinkedinShareJob.perform_later(article.id)
      end
    end

    assert article.reload.shared_on_linkedin?, "Article should be marked as shared after retry"
  end

  test "skips sharing if article already shared" do
    article = create_article!
    article.mark_shared_on_linkedin!

    LinkedinShareJob.perform_now(article.id)

    # Should not make API request
    assert_not_requested :post, "https://api.linkedin.com/rest/posts"
    assert article.reload.shared_on_linkedin?
  end

  test "skips if LinkedIn integration disabled" do
    @linkedin_config.enabled = false
    article = create_article!

    LinkedinShareJob.perform_now(article.id)

    # Should not make API request
    assert_not_requested :post, "https://api.linkedin.com/rest/posts"
    assert_not article.reload.shared_on_linkedin?
  end

  test "includes article title and URL in post" do
    article = create_article!

    stub_linkedin_api_success

    LinkedinShareJob.perform_now(article.id)

    assert_requested :post, "https://api.linkedin.com/rest/posts" do |req|
      body = JSON.parse(req.body)
      body["content"]["article"]["title"] == article.title &&
        body["content"]["article"]["source"].include?(article.id.to_s)
    end
  end

  test "generates valid URL when APP_PORT is nil" do
    article = create_article!

    # Set APP_PORT to nil
    original_port = ENV["APP_PORT"]
    ENV["APP_PORT"] = nil

    stub_linkedin_api_success

    LinkedinShareJob.perform_now(article.id)

    # Verify the URL in the request doesn't contain invalid port syntax like "host:{}/path"
    assert_requested :post, "https://api.linkedin.com/rest/posts" do |req|
      body = JSON.parse(req.body)
      url = body["content"]["article"]["source"]
      assert_valid_url_format(url)
      true
    end
  ensure
    ENV["APP_PORT"] = original_port
  end

  test "generates valid URL when APP_PORT is empty string" do
    article = create_article!

    # Set APP_PORT to empty string
    original_port = ENV["APP_PORT"]
    ENV["APP_PORT"] = ""

    stub_linkedin_api_success

    LinkedinShareJob.perform_now(article.id)

    # Verify the URL in the request doesn't contain invalid port syntax
    assert_requested :post, "https://api.linkedin.com/rest/posts" do |req|
      body = JSON.parse(req.body)
      url = body["content"]["article"]["source"]
      assert_valid_url_format(url)
      true
    end
  ensure
    ENV["APP_PORT"] = original_port
  end

  test "generates valid URL when default_url_options has nil port" do
    article = create_article!

    # Store original default_url_options
    original_options = Rails.application.routes.default_url_options.dup

    # Set default_url_options with nil port
    Rails.application.routes.default_url_options = {
      host: "test.example.com",
      protocol: "https",
      port: nil
    }

    stub_linkedin_api_success

    LinkedinShareJob.perform_now(article.id)

    # Verify the URL in the request doesn't contain invalid port syntax
    assert_requested :post, "https://api.linkedin.com/rest/posts" do |req|
      body = JSON.parse(req.body)
      url = body["content"]["article"]["source"]
      assert_valid_url_format(url)
      true
    end
  ensure
    Rails.application.routes.default_url_options = original_options
  end

  test "generates valid URL when default_url_options has empty string port" do
    article = create_article!

    # Store original default_url_options
    original_options = Rails.application.routes.default_url_options.dup

    # Set default_url_options with empty string port
    Rails.application.routes.default_url_options = {
      host: "test.example.com",
      protocol: "https",
      port: ""
    }

    stub_linkedin_api_success

    LinkedinShareJob.perform_now(article.id)

    # Verify the URL in the request doesn't contain invalid port syntax
    assert_requested :post, "https://api.linkedin.com/rest/posts" do |req|
      body = JSON.parse(req.body)
      url = body["content"]["article"]["source"]
      assert_valid_url_format(url)
      true
    end
  ensure
    Rails.application.routes.default_url_options = original_options
  end

  test "includes valid port in URL when APP_PORT is a positive integer" do
    article = create_article!

    # Set APP_PORT to a valid port
    original_port = ENV["APP_PORT"]
    ENV["APP_PORT"] = "3000"

    stub_linkedin_api_success

    LinkedinShareJob.perform_now(article.id)

    # Verify the URL in the request includes the port
    assert_requested :post, "https://api.linkedin.com/rest/posts" do |req|
      body = JSON.parse(req.body)
      url = body["content"]["article"]["source"]
      assert url.include?(":3000"), "URL should contain port 3000: #{url}"
      true
    end
  ensure
    ENV["APP_PORT"] = original_port
  end

  private

  def create_article!
    Article.create!(
      title: "LinkedIn test post",
      user: User.create!(
        first_name: "Test",
        last_name: "User",
        email: "tester-#{SecureRandom.hex(4)}@example.com",
        password: "password123"
      )
    )
  end

  def enable_linkedin_config!
    @linkedin_config.access_token = "test_token_1234567890abc"
    @linkedin_config.author_urn = "urn:li:person:123456"
    @linkedin_config.visibility = "PUBLIC"
    @linkedin_config.enabled = true
  end

  def stub_linkedin_api_success
    stub_request(:post, "https://api.linkedin.com/rest/posts")
      .to_return(status: 201, body: {}.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_linkedin_api_error(code:, body:)
    stub_request(:post, "https://api.linkedin.com/rest/posts")
      .to_return(status: code, body: body)
  end

  # Validates that a URL doesn't contain malformed port syntax
  # Specifically checks for edge cases that can occur with nil or empty port values:
  # - ":{}" - empty port placeholder from string interpolation (e.g., "https://host:{}/path")
  # - ":/" - colon followed immediately by slash, missing port number (e.g., "https://host:/path")
  # The pattern checks if there's a colon in the authority portion (protocol://host:port)
  # that isn't followed by a valid port number
  def assert_valid_url_format(url)
    # Check for the specific ":{}" pattern that occurs with nil port interpolation
    assert_not url.include?(":{}"), "URL should not contain invalid port placeholder: #{url}"
    # The regex matches: ://[^/]+ (protocol separator + everything up to first slash, including host and port)
    # followed by : (a colon within that section) followed by [^0-9] (a non-digit character)
    # This catches malformed ports like :/, :{, :a while allowing valid ports like :3000
    # Examples: ✅ catches "://host:/" and "://host:{", ❌ allows "://host:3000"
    assert_not url.match?(%r{://[^/]+:[^0-9]}), "URL should not contain malformed port after host: #{url}"
  end
end
