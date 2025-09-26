# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview: B-itconsulting
This is a custom-built portfolio website for a freelance IT infrastructure consultant, built with Ruby on Rails 7.1+ and Bootstrap 5. The site features a responsive design, custom SCSS grid system, and dynamic content management for articles.

## Development Commands

### Setup
- `bundle install` - Install Ruby dependencies
- `bin/setup` - Initialize the Rails application
- `bin/rails db:create db:migrate` - Set up the database

### Development Server
- `bin/dev` - Start development server with Foreman (includes CSS watching via Tailwind)
- `bin/rails server` - Start Rails server only (port 3000)

### Database
- `bin/rails db:migrate` - Run pending migrations
- `bin/rails db:seed` - Seed database
- `bin/rails db:reset` - Reset database (drop, create, migrate, seed)

### Code Quality
- `bundle exec rubocop` - Run RuboCop linter
- `bundle exec rubocop -A` - Auto-correct RuboCop violations
- Line length limit: 120 characters (configured in .rubocop.yml)

### Testing
- `bin/rails test` - Run all tests
- `bin/rails test:system` - Run system tests with Capybara/Selenium

### Rails Console & Tasks
- `bin/rails console` - Interactive Rails console
- `bin/rails routes` - Display all application routes
- `bin/rails assets:precompile` - Precompile assets for production

## Architecture & Structure

### Application Structure
This is a standard Rails 7 application with the following key characteristics:

**Authentication & Authorization**
- Uses Devise gem for user authentication
- User model with standard Devise modules

**Content Management**
- Article model for blog/portfolio content management
- Contact form functionality with email notifications via ContactMailer
- Static pages controller handling main site pages (home, about, competences, legal pages)

**Frontend Technology Stack**
- Bootstrap 5 for responsive design framework
- Custom SCSS with Autoprefixer for cross-browser compatibility
- Font Awesome icons integration
- Stimulus.js for JavaScript interactivity
- Importmap for JavaScript module management
- Custom carousel implementation with infinite loop scrolling

**Asset Management**
- Cloudinary integration for image hosting and optimization
- Sprockets asset pipeline
- SCSS compilation with sassc-rails

### Key Controllers & Routes
- `PagesController` - Main static pages (home, about, competences, legal pages)
- `ArticlesController` - Article display (index, show, new)
- `ContactsController` - Contact form handling
- `ApplicationController` - Base controller with shared functionality

### Database
- PostgreSQL database
- Uses standard Rails Active Record ORM
- Models: User (Devise), Article, and ApplicationRecord base class

### Configuration Notes
- Ruby version: 3.3.5
- Rails version: 7.1.5+
- Development environment uses dotenv-rails for environment variables
- RuboCop configured with relaxed rules for rapid development
- Procfile.dev configured for Foreman-based development with CSS watching

### Deployment
- Configured for Heroku deployment
- Uses Puma web server
- Docker support available (Dockerfile present)
- Production assets served via Cloudinary CDN

## Development Notes
- The application follows Rails conventions for MVC architecture
- Uses Simple Form gem (from GitHub) for form building
- Custom SCSS grid system aligned with Figma designs
- Responsive design implemented across all screen sizes
- Contact form includes email notifications
- Article management system for portfolio content

## Important Files
- `config/routes.rb` - Application routing configuration
- `app/controllers/pages_controller.rb` - Main controller (large file with extensive content)
- `Procfile.dev` - Development process configuration
- `.rubocop.yml` - Code style configuration
- `config/storage.yml` - Active Storage configuration (Cloudinary)

## How to run locally
- Ruby: 3.2+ via asdf or rbenv
- Setup: `bin/setup` then `bin/dev` (or `rails s`)
- Console: `rails c`; DB: `rails db:migrate`

## Claude’s role
- Summarize & navigate code; propose diffs; write/modify files; run bash safely; manage git branches/commits/PR descriptions.
- Always show a plan first for multi-file changes.
- Use **small, reviewable PR-sized diffs**.

## Guardrails
- Never paste or read `.env*`, `config/credentials*`, API keys, or secrets.
- Do not touch production configs, CI secrets, or cloud infra.
- For Rails:
  - Prefer migrations over manual schema edits.
  - Update model validations + tests alongside schema changes.
  - For Hotwire/Stimulus: keep controllers small; explain targets/values.
- For JS/CSS: keep selectors minimal; avoid global leaks.

## Commands Claude may run (dev-only)
- Rails: `bin/rails db:migrate db:rollback`, `bin/rspec`, `bin/rails test`, `bundle exec rubocop -A`
- JS/CSS: `npm run lint`, `npm run build`
- Git: `git switch -c <branch>`, `git add -A`, `git commit -m "<msg>"`
- Do **not** push or deploy without explicit approval.

## Definition of Done for a change
- All tests pass; lints clean.
- Diff is documented with a short rationale + manual test notes.
- If user-facing, update copy & i18n.
- If complex, add or update docs in `docs/`.

## Backlog hints
- Cookie consent: implement compliant banner (FR) with categories + prior consent, store in cookie, respect on page load.
- Contact form: server validations + spam guard; deliver via Action Mailer; success/failure UX.
