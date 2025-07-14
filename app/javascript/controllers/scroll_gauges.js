document.addEventListener("turbo:load", () => {
  observeGauges();
});

export function observeGauges() {
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      const gauge = entry.target;
      if (!entry.isIntersecting) return;

      const label = gauge.querySelector(".gauge__title");
      const value = parseInt(gauge.dataset.value, 10);
      const degrees = (value / 100) * 180;

      // ✅ Reset rotation to force animation
      gauge.style.setProperty("--rotation", `-1deg`);
      if (label) label.textContent = "0%";

      // ✅ Step 1: animate number
      let current = 0;
      const step = () => {
        if (current <= value) {
          label.textContent = `${current}%`;
          current++;
          requestAnimationFrame(step);
        }
      };
      step();

      // ✅ Step 2: apply real rotation on next frame
      requestAnimationFrame(() => {
        gauge.style.setProperty("--rotation", `${degrees}deg`);
      });
    });
  }, { threshold: 0.5 });

  document.querySelectorAll(".gauge").forEach(gauge => {
    observer.observe(gauge);
  });
}
