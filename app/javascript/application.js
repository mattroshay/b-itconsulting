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
    if (document.documentElement.scrollTop > 100) {
      scrollTop.classList.add("show");
    } else {
      scrollTop.classList.remove("show");
    }
  };

  scrollTop.addEventListener("click", function () {
    window.scrollTo({
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

  let scrollSpeed = 0.5;
  let scrollBuffer = 0;
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

// only one experience credential open at a time

document.addEventListener("DOMContentLoaded", function() {
    const allDetails = document.querySelectorAll(".experience-section details");

    allDetails.forEach(detail => {
      detail.addEventListener("toggle", () => {
        if (detail.open) {
          // Close every other <details>
          allDetails.forEach(other => {
            if (other !== detail) other.open = false;
          });
        }
      });
    });
  });

// end experience credential

// video on homepage

document.addEventListener("turbo:load", () => {
  const openBtn = document.getElementById("toggle-video-btn");
  const modal = document.getElementById("video-modal");
  const closeBtn = document.getElementById("close-video-modal");
  const iframe = modal?.querySelector("iframe");
  const backdrop = modal?.querySelector(".video-modal-backdrop");

  if (!openBtn || !modal || !closeBtn || !iframe) return;

  const animationType = "fade"; // Change to "zoom" if you want zoom effect

  const showModal = () => {
    modal.classList.remove("hidden", "fade-out", "zoom-out");
    modal.classList.add(`${animationType}-in`);
  };

  const hideModal = () => {
    modal.classList.remove(`${animationType}-in`);
    modal.classList.add(`${animationType}-out`);

    // Delay hiding until animation completes
    setTimeout(() => {
      modal.classList.add("hidden");
      modal.classList.remove(`${animationType}-out`);

      // Stop playback by resetting iframe src
      const src = iframe.getAttribute("src");
      iframe.setAttribute("src", src);
    }, 300); // Match your animation duration
  };

  openBtn.addEventListener("click", (e) => {
    e.preventDefault();
    showModal();
  });

  closeBtn.addEventListener("click", hideModal);
  backdrop.addEventListener("click", hideModal);
});

// end video on homepage
