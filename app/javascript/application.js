// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "@popperjs/core"
import "bootstrap"
import "@splidejs/splide";

//scrolltop-button
document.addEventListener("turbo:load", function () {
  var scrollTop = document.getElementById("scrollTop");

  if (!scrollTop) return; // safeguard in case the button doesn't exist on the page

  window.onscroll = function () {
    scrollfunction();
  };

  function scrollfunction() {
    if (
      document.body.scrollTop > 95 ||
      document.documentElement.scrollTop > 95
    ) {
      scrollTop.style.display = "block";
    } else {
      scrollTop.style.display = "none";
    }
  }

  scrollTop.addEventListener("click", function () {
    window.scrollTo({
      left: 0,
      top: 0,
      behavior: "smooth",
    });
  });
});
//scrolltop-button end
