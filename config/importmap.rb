# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "bootstrap", to: "bootstrap.min.js", preload: true
pin "@popperjs/core", to: "popper.js", preload: true
pin "scrolltop_button", to: "scrolltop_button.js"
pin "one_at_a_time", to: "one_at_a_time.js"
pin "carousel_auto_scroll", to: "carousel_auto_scroll.js"
pin "video_player", to: "video_player.js"
