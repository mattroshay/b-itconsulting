# frozen_string_literal: true

require "json"
require "net/http"
require "securerandom"
require "uri"

module LinkedinTasks
  module_function

  def require_env!(key)
    value = ENV[key]
    cleaned = value.to_s.strip
    return cleaned unless cleaned.empty?

    abort("ENV['#{key}'] is missing. Please set it in .env or your shell.")
  end

  def https_request(uri, request)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.open_timeout = 10
      http.read_timeout = 10
      http.request(request)
    end
  end

  def print_json(response)
    puts "Status: #{response.code}"
    body = response.body.to_s
    if body.empty?
      puts "(no response body)"
      return
    end

    begin
      json = JSON.parse(body)
      puts JSON.pretty_generate(json)
    rescue JSON::ParserError
      puts body
    end
  end
end

namespace :linkedin do
  namespace :oauth do
    desc "Print the authorization URL needed to generate a new LinkedIn token"
    task :url, [:scopes] do |_, args|
      client_id = LinkedinTasks.require_env!("LINKEDIN_CLIENT_ID")
      redirect_uri = LinkedinTasks.require_env!("LINKEDIN_REDIRECT_URI")

      scopes = args[:scopes].to_s.strip
      scopes = "w_member_social r_liteprofile" if scopes.empty?

      state = SecureRandom.hex(12)
      query = URI.encode_www_form(
        response_type: "code",
        client_id: client_id,
        redirect_uri: redirect_uri,
        scope: scopes,
        state: state
      )

      puts "Open this URL in your browser to authorize LinkedIn:"
      puts "https://www.linkedin.com/oauth/v2/authorization?#{query}"
      puts
      puts "State token (keep it to validate callback): #{state}"
      puts "Scopes: #{scopes}"
    end

    desc "Exchange a LinkedIn OAuth authorization code for an access token"
    task :exchange, [:code] do |_, args|
      code = args[:code].to_s.strip
      abort("Usage: bin/rails \"linkedin:oauth:exchange[AUTH_CODE]\"") if code.empty?

      client_id = LinkedinTasks.require_env!("LINKEDIN_CLIENT_ID")
      client_secret = LinkedinTasks.require_env!("LINKEDIN_CLIENT_SECRET")
      redirect_uri = LinkedinTasks.require_env!("LINKEDIN_REDIRECT_URI")

      uri = URI("https://www.linkedin.com/oauth/v2/accessToken")
      request = Net::HTTP::Post.new(uri)
      request.set_form_data(
        grant_type: "authorization_code",
        code: code,
        client_id: client_id,
        client_secret: client_secret,
        redirect_uri: redirect_uri
      )

      response = LinkedinTasks.https_request(uri, request)
      LinkedinTasks.print_json(response)

      return unless response.code.to_i == 200

      data = JSON.parse(response.body)
      puts
      puts "✅ Copy the 'access_token' above into LINKEDIN_ACCESS_TOKEN."
      puts "   Token lifetime: #{data['expires_in']} seconds" if data["expires_in"]
      if data["refresh_token"]
        puts "   Refresh token present – store it securely if you plan to automate refreshes."
      end
    end
  end

  namespace :token do
    desc "Call /v2/me to verify the configured token and print the proper LINKEDIN_AUTHOR_URN"
    task inspect: :environment do
      token = LinkedinTasks.require_env!("LINKEDIN_ACCESS_TOKEN")

      uri = URI("https://api.linkedin.com/v2/me?projection=(id,localizedFirstName,localizedLastName)")
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{token}"
      api_version = ENV["LINKEDIN_API_VERSION"] || "202411"
      request["LinkedIn-Version"] = api_version
      request["X-Restli-Protocol-Version"] = "2.0.0"

      response = LinkedinTasks.https_request(uri, request)

      if response.code.to_i != 200
        puts "LinkedIn rejected the token. Response:"
        LinkedinTasks.print_json(response)
        puts
        puts "Ensure your token has the w_member_social scope (or w_organization_social for company posts)."
        return
      end

      data = JSON.parse(response.body)
      person_id = data["id"]
      first_name = data["localizedFirstName"]
      last_name = data["localizedLastName"]

      puts "LinkedIn token valid ✅"
      puts "Profile: #{first_name} #{last_name} (id: #{person_id})"
      puts
      puts "Set your LINKEDIN_AUTHOR_URN to:"
      puts "  urn:li:person:#{person_id}"
      puts
      puts "If you intend to post as a company page instead, use the organization URN:"
      puts "  urn:li:organization:YOUR_COMPANY_ID"
      puts "and be sure the token has the w_organization_social scope and you are an admin."
    end
  end
end
