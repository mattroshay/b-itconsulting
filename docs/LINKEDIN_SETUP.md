# LinkedIn API Integration Setup Guide

This guide explains how to set up automatic LinkedIn sharing for new articles published on the B-IT Consulting website.

## Overview

When a new article is created, the system automatically:
1. Queues a background job to share the article on LinkedIn
2. Posts the article with title, excerpt, and link to your LinkedIn profile
3. Tracks sharing status to prevent duplicates
4. Handles errors gracefully with retry logic

## Prerequisites

- A LinkedIn account (personal or company page)
- Admin access to create LinkedIn Apps
- Your website must be publicly accessible (for article URLs)

## Setup Steps

### 1. Create a LinkedIn App

1. Go to [LinkedIn Developers](https://www.linkedin.com/developers/apps)
2. Click "Create app"
3. Fill in the required information:
   - **App name**: B-IT Consulting Auto-Share
   - **LinkedIn Page**: Your company page (or leave empty for personal)
   - **App logo**: Upload your logo
   - **Legal agreement**: Accept the terms

### 2. Configure OAuth 2.0 Scopes

1. In your app dashboard, go to the "Products" tab
2. Request access to "Share on LinkedIn" product
3. Wait for approval (usually instant for personal use)
4. Go to "Auth" tab and verify you have these scopes:
   - `w_member_social` - Required to post on behalf of the user
   - `r_liteprofile` - Required to get user profile info

### 3. Get Your Access Token

#### Option A: Using OAuth 2.0 Flow (Recommended for Production)

1. In the "Auth" tab, add redirect URL: `https://your-domain.com/auth/linkedin/callback`
2. Note your **Client ID** and **Client Secret**
3. Build authorization URL:
   ```
   https://www.linkedin.com/oauth/v2/authorization?response_type=code&client_id=YOUR_CLIENT_ID&redirect_uri=YOUR_REDIRECT_URI&scope=w_member_social%20r_liteprofile
   ```
4. Visit the URL in your browser and authorize
5. You'll be redirected with a `code` parameter
6. Exchange the code for an access token:
   ```bash
   curl -X POST https://www.linkedin.com/oauth/v2/accessToken \
     -H 'Content-Type: application/x-www-form-urlencoded' \
     -d 'grant_type=authorization_code' \
     -d 'code=YOUR_AUTHORIZATION_CODE' \
     -d 'client_id=YOUR_CLIENT_ID' \
     -d 'client_secret=YOUR_CLIENT_SECRET' \
     -d 'redirect_uri=YOUR_REDIRECT_URI'
   ```
7. Save the `access_token` from the response

#### Option B: Quick Test Token (Development Only)

1. Use LinkedIn's [API Inspector](https://www.linkedin.com/developers/tools/api-inspector)
2. This provides a 60-day token for testing
3. **Not recommended for production** - tokens expire

#### Helper Commands You Can Run Locally

The repo includes Rake helpers so you don't have to hand-craft OAuth URLs or cURL calls:

```bash
# 1. Print the authorization URL (default scopes: w_member_social r_liteprofile)
bin/rails linkedin:oauth:url

# 2. After LinkedIn redirects back with ?code=XYZ, exchange it for a token
bin/rails "linkedin:oauth:exchange[PASTE_AUTH_CODE_HERE]"

# 3. Verify the token works and copy the suggested LINKEDIN_AUTHOR_URN
bin/rails linkedin:token:inspect
```

These commands rely on the `LINKEDIN_CLIENT_ID`, `LINKEDIN_CLIENT_SECRET`, and `LINKEDIN_REDIRECT_URI`
variables already listed below, so double-check they are set first.

### 4. Get Your LinkedIn Person URN

Run this command with your access token:

```bash
curl -X GET https://api.linkedin.com/v2/me \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN'
```

The response will include your person ID:
```json
{
  "id": "ABC123XYZ",
  ...
}
```

Your URN format is: `urn:li:person:ABC123XYZ`

### 5. Configure Environment Variables

Add these to your `.env` file (copy from `.env.example`):

```bash
# LinkedIn API Configuration
LINKEDIN_ACCESS_TOKEN=your_access_token_here
LINKEDIN_AUTHOR_URN=urn:li:person:your_id_here
LINKEDIN_POST_VISIBILITY=PUBLIC  # or CONNECTIONS

# Application URLs (required for article links)
APP_HOST=www.your-domain.com
APP_PROTOCOL=https
```

### 6. Run Database Migration

```bash
bin/rails db:migrate
```

This adds the `linkedin_shared_at` timestamp column to the articles table.

### 7. Test the Integration

#### In Development

1. Start your Rails server:
   ```bash
   bin/dev
   ```

2. Create a test article through the UI
3. Check logs for LinkedIn sharing activity:
   ```bash
   tail -f log/development.log | grep LinkedIn
   ```

4. Verify the post appears on your LinkedIn profile

#### Test the Job Manually

```ruby
# In Rails console (bin/rails console)
article = Article.last
LinkedinShareJob.perform_now(article.id)
```

## Token Refresh Strategy

LinkedIn access tokens expire after **60 days** by default. You have two options:

### Option 1: Manual Token Refresh
- Set a calendar reminder for every 55 days
- Repeat the OAuth flow to get a new token
- Update `LINKEDIN_ACCESS_TOKEN` environment variable
- Restart your Rails server

### Option 2: Implement Automatic Refresh (Recommended)
This requires storing refresh tokens and implementing a refresh mechanism:

1. Store `refresh_token` from OAuth response
2. Before token expiry, exchange refresh token for new access token:
   ```bash
   curl -X POST https://www.linkedin.com/oauth/v2/accessToken \
     -H 'Content-Type: application/x-www-form-urlencoded' \
     -d 'grant_type=refresh_token' \
     -d 'refresh_token=YOUR_REFRESH_TOKEN' \
     -d 'client_id=YOUR_CLIENT_ID' \
     -d 'client_secret=YOUR_CLIENT_SECRET'
   ```
3. Update the token in your database/configuration

## Monitoring & Troubleshooting

### Check Sharing Status

```ruby
# In Rails console
article = Article.find(123)
article.shared_on_linkedin?  # => true/false
article.linkedin_shared_at   # => timestamp or nil
```

### Common Issues

#### "LinkedIn integration disabled"
- Check that `LINKEDIN_ACCESS_TOKEN` and `LINKEDIN_AUTHOR_URN` are set
- Restart Rails server after adding environment variables

#### "LinkedIn access token expired or invalid" (401 error)
- Your token has expired (60 days)
- Refresh your token using the OAuth flow
- Check that the token hasn't been revoked in LinkedIn app settings

#### "LinkedIn API rate limit exceeded" (429 error)
- LinkedIn has rate limits per app and per user
- Wait before retrying (limits usually reset within an hour)
- Consider implementing exponential backoff

#### Article not posting
- Check `log/production.log` or `log/development.log` for errors
- Verify `APP_HOST` and `APP_PROTOCOL` are set correctly
- Ensure your site is publicly accessible (LinkedIn validates URLs)
- Check ActiveJob is configured (default async adapter should work)
- Run `bin/rails linkedin:token:inspect` to ensure your token is valid and to confirm the correct
  `LINKEDIN_AUTHOR_URN` (it must be the numeric person/organization id, not your vanity slug)

### View Job Queue

```ruby
# In Rails console
Delayed::Job.all  # If using Delayed Job
# or check your job backend's queue
```

## Security Best Practices

1. **Never commit** `.env` file to git (it's in `.gitignore`)
2. **Rotate tokens regularly** - refresh every 50-55 days
3. **Use environment-specific tokens** - different tokens for dev/staging/prod
4. **Monitor failed jobs** - set up alerts for repeated failures
5. **Restrict app permissions** - only request necessary OAuth scopes

## Production Deployment

### Heroku

```bash
heroku config:set LINKEDIN_ACCESS_TOKEN=your_token
heroku config:set LINKEDIN_AUTHOR_URN=urn:li:person:your_id
heroku config:set LINKEDIN_POST_VISIBILITY=PUBLIC
heroku config:set APP_HOST=www.your-domain.com
heroku config:set APP_PROTOCOL=https
```

### Other Platforms

Add the environment variables through your platform's configuration UI or deployment files.

## Rate Limits

LinkedIn API rate limits (at the time of writing):
- **Posts**: ~100 per day per person
- **API calls**: Varies by endpoint and app status

Monitor your usage and implement backoff strategies if needed.

## Need Help?

- [LinkedIn API Documentation](https://docs.microsoft.com/en-us/linkedin/)
- [LinkedIn Developer Portal](https://www.linkedin.com/developers/)
- [OAuth 2.0 Guide](https://docs.microsoft.com/en-us/linkedin/shared/authentication/authentication)
