document.addEventListener("DOMContentLoaded", () => {
  const gauges = document.querySelectorAll(".gauge");

  gauges.forEach(gauge => {
    const value = parseInt(gauge.dataset.value, 10);
    const degrees = Math.round((value / 100) * 180);
    const title = gauge.querySelector(".gauge__title");

    // Animate number inside the gauge
    let current = 0;
    const step = () => {
      if (current < value) {
        current++;
        title.innerText = `${current}%`;
        requestAnimationFrame(step);
      } else {
        title.innerText = `${value}%`;
      }
    };
    step();

    // Rotate the gauge arc
    gauge.style.setProperty("--rotation", `${degrees}deg`);
  });
});
