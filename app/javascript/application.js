// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "@popperjs/core"
import "bootstrap"

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

// carousel auto-scroll
document.addEventListener("turbo:load", () => {
  const track = document.getElementById("customCarouselTrack");
  if (!track) return;

  let scrollSpeed = 0.3; // fractional value
  let scrollBuffer = 0;   // keeps sub-pixel precision
  let rafId;

  const scroll = () => {
    scrollBuffer += scrollSpeed;

    if (scrollBuffer >= 1) {
      track.scrollLeft += Math.floor(scrollBuffer);
      scrollBuffer -= Math.floor(scrollBuffer);
    }

    if (track.scrollLeft >= track.scrollWidth / 2) {
      track.scrollLeft = 0;
      scrollBuffer = 0;
    }

    rafId = requestAnimationFrame(scroll);
  };

  scroll();

  track.addEventListener("mouseenter", () => cancelAnimationFrame(rafId));
  track.addEventListener("mouseleave", scroll);
});
// carousel auto-scroll end
