# Google reCAPTCHA Integration Setup Guide

This guide explains how to set up Google reCAPTCHA v2 protection for the contact form on the B-IT Consulting website.

## Overview

The contact form uses Google reCAPTCHA v2 ("I'm not a robot" checkbox) to:
1. Prevent spam submissions from automated bots
2. Protect the contact form from abuse
3. Ensure legitimate users can still easily submit inquiries

## Prerequisites

- A Google account
- Admin access to your website
- Your website must be accessible (localhost is fine for development)

## Setup Steps

### 1. Register Your Site with Google reCAPTCHA

1. Go to [Google reCAPTCHA Admin Console](https://www.google.com/recaptcha/admin)
2. Sign in with your Google account
3. Click the **+** button to register a new site

### 2. Configure reCAPTCHA Settings

Fill in the registration form:

**Label**: Give your site a recognizable name
- Example: `B-IT Consulting - Production`
- Example: `B-IT Consulting - Development`

**reCAPTCHA type**: Select **reCAPTCHA v2**
- Choose: **"I'm not a robot" Checkbox**

**Domains**: Add your website domain(s)
- Production: `www.your-domain.com`, `your-domain.com`
- Development: `localhost` (for local testing)
- You can add multiple domains to one site key

**Owners**: (Optional) Add additional Google accounts that can manage this reCAPTCHA

**Accept the reCAPTCHA Terms of Service**

Click **Submit**

### 3. Get Your API Keys

After registration, you'll see two keys:

- **Site Key** (Public key): Used in your HTML forms
- **Secret Key** (Private key): Used for server-side verification

**Important**: Keep your Secret Key confidential. Never commit it to version control.

### 4. Configure Environment Variables

Add these to your `.env` file:

```bash
# Google reCAPTCHA Configuration
RECAPTCHA_SITE_KEY=your_site_key_here
RECAPTCHA_SECRET_KEY=your_secret_key_here
```

For local development, you can also add them to `.env.local`:

```bash
# .env.local (for development)
RECAPTCHA_SITE_KEY=your_development_site_key
RECAPTCHA_SECRET_KEY=your_development_secret_key
```

### 5. Restart Your Rails Server

After adding the environment variables:

```bash
# Stop your current server (Ctrl+C)
# Restart with:
bin/dev
# or
bin/rails server
```

### 6. Test the Integration

#### In Development

1. Start your Rails server:
   ```bash
   bin/dev
   ```

2. Visit the contact form:
   ```
   http://localhost:3000/contact
   ```

3. Fill out the form and verify:
   - The reCAPTCHA checkbox appears
   - Submitting without checking the box shows an error
   - Submitting with the checkbox checked works correctly

#### Test reCAPTCHA Verification

```ruby
# In Rails console (bin/rails console)
# Test with a valid token (you'll need to capture one from a real submission)
controller = ContactsController.new
controller.verify_recaptcha
```

## How It Works

### Frontend Integration

The contact form includes the reCAPTCHA widget:

```erb
<%= recaptcha_tags %>
```

This renders a "I'm not a robot" checkbox that users must complete.

### Backend Verification

The controller verifies the reCAPTCHA response:

```ruby
unless verify_recaptcha(model: @form)
  flash.now[:alert] = "Veuillez confirmer que vous n'êtes pas un robot."
  return render :new, status: :unprocessable_entity
end
```

The verification:
1. Sends the user's response to Google's API
2. Validates the response is genuine
3. Blocks the form submission if verification fails

## Different reCAPTCHA Keys for Different Environments

It's recommended to use separate reCAPTCHA keys for each environment:

### Development
- Register `localhost` domain
- Use in `.env.local` or `.env.development`

### Staging
- Register your staging domain
- Set environment variables on staging server

### Production
- Register your production domain(s)
- Set environment variables on production server

## Production Deployment

### Heroku

```bash
heroku config:set RECAPTCHA_SITE_KEY=your_production_site_key
heroku config:set RECAPTCHA_SECRET_KEY=your_production_secret_key
```

### Other Platforms

Add the environment variables through your platform's configuration UI or deployment files.

## Monitoring & Troubleshooting

### Common Issues

#### reCAPTCHA widget doesn't appear
- Check that `RECAPTCHA_SITE_KEY` is set correctly
- Verify you've restarted the Rails server after setting environment variables
- Check browser console for JavaScript errors
- Ensure your domain is registered in Google reCAPTCHA admin

#### "Veuillez confirmer que vous n'êtes pas un robot" error appears even after solving
- Check that `RECAPTCHA_SECRET_KEY` is set correctly
- Verify the secret key matches the site key
- Check Rails logs for reCAPTCHA verification errors:
  ```bash
  tail -f log/development.log | grep -i recaptcha
  ```

#### reCAPTCHA verification fails in production but works locally
- Ensure your production domain is registered in reCAPTCHA admin
- Verify production environment variables are set
- Check that you're using the correct key pair (production keys, not development)

#### "Hostname verification failed" error
- Your domain isn't registered in Google reCAPTCHA admin
- Add your production domain to the allowed domains list

### View reCAPTCHA Analytics

1. Go to [Google reCAPTCHA Admin Console](https://www.google.com/recaptcha/admin)
2. Select your site
3. View analytics for:
   - Request volume
   - Verification success rate
   - Potential attacks blocked

## Testing in Development

### Bypass reCAPTCHA in Tests

The test suite stubs reCAPTCHA verification:

```ruby
# In test/controllers/contacts_controller_test.rb
ContactsController.any_instance.stubs(:verify_recaptcha).returns(true)
```

This allows tests to run without requiring actual reCAPTCHA tokens.

### Test with Real reCAPTCHA Locally

1. Register `localhost` in Google reCAPTCHA admin
2. Set environment variables with localhost keys
3. Test the form manually in your browser

## Security Best Practices

1. **Never commit** `.env` file to git (it's in `.gitignore`)
2. **Keep secret key private** - never expose it in client-side code
3. **Use different keys** for development, staging, and production
4. **Monitor analytics** - watch for unusual patterns that might indicate attacks
5. **Rotate keys if compromised** - generate new keys and update configuration
6. **Validate on server-side** - never rely only on client-side validation

## reCAPTCHA Versions

This integration uses **reCAPTCHA v2** (checkbox). Google also offers:

- **reCAPTCHA v3**: Invisible, score-based detection
- **reCAPTCHA Enterprise**: Advanced features with more customization

To upgrade to v3 or Enterprise, you would need to:
1. Register a new site with the desired version
2. Update the implementation code
3. Adjust the verification logic

## Rate Limits

Google reCAPTCHA has generous rate limits:
- **1,000,000 assessments per month** (free tier)
- No strict daily limits for v2 checkbox

For most websites, you won't hit these limits.

## Need Help?

- [Google reCAPTCHA Documentation](https://developers.google.com/recaptcha)
- [reCAPTCHA Admin Console](https://www.google.com/recaptcha/admin)
- [reCAPTCHA Ruby Gem Documentation](https://github.com/ambethia/recaptcha)
- [FAQ and Troubleshooting](https://developers.google.com/recaptcha/docs/faq)
