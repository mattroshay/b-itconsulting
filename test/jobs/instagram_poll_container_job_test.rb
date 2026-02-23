# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"
require "securerandom"

class InstagramPollContainerJobTest < ActiveJob::TestCase
  CONTAINER_ID = "container_123"
  ARTICLE_ID   = 42

  setup do
    @instagram_config = Rails.application.config.x.instagram
    @original_settings = {
      access_token: @instagram_config.access_token,
      ig_user_id:   @instagram_config.ig_user_id,
      enabled:      @instagram_config.enabled
    }
    @instagram_config.access_token = "ig_test_token"
    @instagram_config.ig_user_id   = "1234567890"
    @instagram_config.enabled      = true
    WebMock.enable!
  end

  teardown do
    @original_settings.each { |k, v| @instagram_config.public_send("#{k}=", v) }
    WebMock.disable!
  end

  test "publishes container when FINISHED and marks article as shared" do
    article = create_article!
    stub_status("FINISHED")
    stub_publish

    InstagramPollContainerJob.perform_now(article.id, CONTAINER_ID)

    assert article.reload.shared_on_instagram?
    assert_equal "media_456", article.instagram_media_id
  end

  test "raises ContainerPendingError when container is still IN_PROGRESS" do
    stub_status("IN_PROGRESS")

    assert_raises(InstagramPollContainerJob::ContainerPendingError) do
      InstagramPollContainerJob.perform_now(ARTICLE_ID, CONTAINER_ID)
    end
  end

  test "raises Instagram::Error when container reports ERROR status" do
    stub_status("ERROR")

    assert_raises(Instagram::Error) do
      InstagramPollContainerJob.perform_now(ARTICLE_ID, CONTAINER_ID)
    end
  end

  test "discards job when article is not found" do
    stub_status("FINISHED")
    stub_publish

    assert_nothing_raised do
      InstagramPollContainerJob.perform_now(0, CONTAINER_ID)
    end
  end

  private

  def create_article!
    Article.create!(
      title: "Poll job test",
      user: User.create!(
        first_name: "Poll",
        last_name: "Tester",
        email: "poll-tester-#{SecureRandom.hex(4)}@example.com",
        password: "password123"
      )
    )
  end

  def stub_status(status_code)
    stub_request(:get, "https://graph.facebook.com/v20.0/#{CONTAINER_ID}")
      .with(query: hash_including("fields" => "status_code"))
      .to_return(
        status: 200,
        body: { status_code: status_code }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_publish
    stub_request(:post, "https://graph.facebook.com/v20.0/#{@instagram_config.ig_user_id}/media_publish")
      .to_return(status: 200, body: { id: "media_456" }.to_json, headers: { "Content-Type" => "application/json" })
  end
end
