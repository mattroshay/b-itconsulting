// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "@popperjs/core"
import "bootstrap"


import { observeGauges } from "./gauge";
import { initCookieConsent } from "./cookie_consent";

document.addEventListener("turbo:load", () => {
  observeGauges();
  initCookieConsent();
});
