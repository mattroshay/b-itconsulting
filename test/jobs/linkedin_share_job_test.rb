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

  test "swallows LinkedIn errors but logs them" do
    article = create_article!

    stub_linkedin_api_error(code: 400, body: "Bad Request")

    assert_nothing_raised { LinkedinShareJob.perform_now(article.id) }

    # Article should not be marked as shared if error occurred
    assert_not article.reload.shared_on_linkedin?
  end

  test "handles token expiration" do
    article = create_article!

    stub_linkedin_api_error(code: 401, body: "Unauthorized")

    assert_nothing_raised { LinkedinShareJob.perform_now(article.id) }
    assert_not article.reload.shared_on_linkedin?
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

  test "skips if linkedin integration disabled" do
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
    @linkedin_config.access_token = "test_token"
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
end
