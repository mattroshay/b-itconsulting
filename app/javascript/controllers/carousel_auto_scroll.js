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

