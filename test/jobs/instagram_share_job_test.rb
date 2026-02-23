# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"
require "securerandom"

class InstagramShareJobTest < ActiveJob::TestCase
  setup do
    @instagram_config = Rails.application.config.x.instagram
    @original_instagram_settings = {
      access_token: @instagram_config.access_token,
      ig_user_id: @instagram_config.ig_user_id,
      enabled: @instagram_config.enabled,
      default_hashtags: @instagram_config.default_hashtags
    }

    enable_instagram_config!
    WebMock.enable!
    @original_app_host = ENV["APP_HOST"]
    ENV["APP_HOST"] = "example.com"
  end

  teardown do
    @original_instagram_settings.each do |attr, value|
      @instagram_config.public_send("#{attr}=", value)
    end
    ENV["APP_HOST"] = @original_app_host
    clear_enqueued_jobs
    clear_performed_jobs
    WebMock.disable!
  end

  test "successfully shares article to Instagram" do
    article = create_article_with_media!
    stub_instagram_graph_success

    perform_enqueued_jobs do
      InstagramShareJob.perform_now(article.id)
    end

    assert article.reload.shared_on_instagram?, "Article should be marked as shared"
    assert_equal "media_456", article.instagram_media_id
  end

  test "skips if already shared" do
    article = create_article_with_media!
    article.mark_shared_on_instagram!(media_id: "media_existing")

    InstagramShareJob.perform_now(article.id)

    assert_requested :post, %r{graph\.facebook\.com}, times: 0
  end

  test "skips if integration disabled" do
    @instagram_config.enabled = false
    article = create_article_with_media!

    InstagramShareJob.perform_now(article.id)

    assert_not article.reload.shared_on_instagram?
    assert_requested :post, %r{graph\.facebook\.com}, times: 0
  end

  test "raises on API errors" do
    article = create_article_with_media!

    stub_instagram_container_error

    assert_raises(Instagram::ValidationError) do
      InstagramShareJob.perform_now(article.id)
    end
    assert_not article.reload.shared_on_instagram?
  end

  test "skips article without media attachment" do
    article = Article.create!(
      title: "No media article",
      user: User.create!(
        first_name: "IG",
        last_name: "Tester",
        email: "ig-no-media-#{SecureRandom.hex(4)}@example.com",
        password: "password123"
      )
    )

    InstagramShareJob.perform_now(article.id)

    assert_not article.reload.shared_on_instagram?
    assert_requested :post, %r{graph\.facebook\.com}, times: 0
  end

  test "shares video attachment via video_url parameter" do
    article = create_article_with_media!(content_type: "video/mp4", filename: "sample.mp4")
    stub_instagram_graph_success

    InstagramShareJob.perform_now(article.id)

    assert article.reload.shared_on_instagram?
    assert_requested(:post, "https://graph.facebook.com/v20.0/#{@instagram_config.ig_user_id}/media") do |req|
      params = URI.decode_www_form(req.body).to_h
      params["media_type"] == "VIDEO" && params.key?("video_url") && !params.key?("image_url")
    end
  end

  test "caption includes title, article URL, and hashtags" do
    article = create_article_with_media!
    stub_instagram_graph_success

    InstagramShareJob.perform_now(article.id)

    assert_requested(:post, "https://graph.facebook.com/v20.0/#{@instagram_config.ig_user_id}/media") do |req|
      params = URI.decode_www_form(req.body).to_h
      caption = params["caption"].to_s
      caption.include?(article.title) && caption.match?(%r{https://example\.com/}) && caption.include?("#test")
    end
  end

  test "silently handles rate limit error without raising" do
    article = create_article_with_media!
    stub_request(:post, "https://graph.facebook.com/v20.0/#{@instagram_config.ig_user_id}/media")
      .to_return(
        status: 429,
        body: { error: { message: "API rate limit exceeded" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_nothing_raised { InstagramShareJob.perform_now(article.id) }
    assert_not article.reload.shared_on_instagram?
  end

  test "sends media URL containing APP_HOST for image attachment" do
    article = create_article_with_media!
    stub_instagram_graph_success

    InstagramShareJob.perform_now(article.id)

    assert_requested(:post, "https://graph.facebook.com/v20.0/#{@instagram_config.ig_user_id}/media") do |req|
      params = URI.decode_www_form(req.body).to_h
      params["image_url"].to_s.match?(%r{\Ahttps://example\.com/})
    end
  end

  test "raises on container polling timeout" do
    article = create_article_with_media!
    stub_request(:post, "https://graph.facebook.com/v20.0/#{@instagram_config.ig_user_id}/media")
      .to_return(status: 200, body: { id: "container_123" }.to_json, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "https://graph.facebook.com/v20.0/container_123")
      .with(query: hash_including("fields" => "status_code"))
      .to_return(status: 200, body: { status_code: "IN_PROGRESS" }.to_json, headers: { "Content-Type" => "application/json" })
    Instagram::Publisher.any_instance.stubs(:sleep)

    error = assert_raises(Instagram::Error) { InstagramShareJob.perform_now(article.id) }

    assert_match(/timed out/, error.message)
    assert_not article.reload.shared_on_instagram?
  end

  private

  def create_article_with_media!(content_type: "image/jpeg", filename: "sample.jpg")
    article = Article.create!(
      title: "Instagram test post",
      user: User.create!(
        first_name: "IG",
        last_name: "Tester",
        email: "ig-tester-#{SecureRandom.hex(4)}@example.com",
        password: "password123"
      )
    )

    article.media.attach(
      io: File.open(file_fixture("sample.jpg")),
      filename: filename,
      content_type: content_type
    )
    article
  end

  def enable_instagram_config!
    @instagram_config.access_token = "ig_test_token_abc123"
    @instagram_config.ig_user_id = "1234567890"
    @instagram_config.enabled = true
    @instagram_config.default_hashtags = %w[#test]
  end

  def stub_instagram_graph_success
    stub_request(:post, "https://graph.facebook.com/v20.0/#{@instagram_config.ig_user_id}/media")
      .to_return(status: 200, body: { id: "container_123" }.to_json, headers: { "Content-Type" => "application/json" })

    stub_request(:get, "https://graph.facebook.com/v20.0/container_123")
      .with(query: hash_including("fields" => "status_code"))
      .to_return(status: 200, body: { status_code: "FINISHED" }.to_json, headers: { "Content-Type" => "application/json" })

    stub_request(:post, "https://graph.facebook.com/v20.0/#{@instagram_config.ig_user_id}/media_publish")
      .to_return(status: 200, body: { id: "media_456" }.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_instagram_container_error
    stub_request(:post, "https://graph.facebook.com/v20.0/#{@instagram_config.ig_user_id}/media")
      .to_return(
        status: 400,
        body: { error: { message: "Invalid OAuth 2.0 access token" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
