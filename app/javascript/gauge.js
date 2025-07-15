export function observeGauges() {
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      const gauge = entry.target;

      if (!entry.isIntersecting) {
        // Reset gauge when it leaves view - disable transition temporarily
        const label = gauge.querySelector(".gauge__title");
        if (label) label.textContent = "0%";

        // Temporarily disable transition for instant reset
        gauge.style.transition = "none";
        gauge.style.setProperty("--rotation", "0deg");

        // Force reflow to ensure the reset is applied
        void gauge.offsetWidth;

        // Re-enable transition after a short delay
        setTimeout(() => {
          gauge.style.transition = "";
        }, 50);

        return;
      }

      const label = gauge.querySelector(".gauge__title");
      const value = parseInt(gauge.dataset.value, 10);
      const degrees = (value / 100) * 180; // Assuming 180-degree gauge

      // 1. Ensure transition is disabled for the initial reset
      gauge.style.transition = "none";
      gauge.style.setProperty("--rotation", "0deg");
      if (label) label.textContent = "0%";

      // 2. Force a reflow to ensure the reset state is rendered
      void gauge.offsetWidth;

      // 3. Re-enable transition and animate on the next frame
      requestAnimationFrame(() => {
        gauge.style.transition = ""; // Re-enable CSS transitions
        gauge.style.setProperty("--rotation", `${degrees}deg`);

        // Animate the number
        let current = 0;
        const duration = 1000; // milliseconds for number animation
        const start = performance.now();

        const stepNumber = (currentTime) => {
          const elapsed = currentTime - start;
          const progress = Math.min(elapsed / duration, 1);

          current = Math.floor(progress * value);
          if (label) label.textContent = `${current}%`;

          if (progress < 1) {
            requestAnimationFrame(stepNumber);
          } else {
            if (label) label.textContent = `${value}%`;
          }
        };
        requestAnimationFrame(stepNumber);
      });
    });
  }, { threshold: 0.5 });

  document.querySelectorAll(".gauge").forEach(gauge => {
    observer.observe(gauge);
  });
}
