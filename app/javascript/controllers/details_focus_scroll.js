document.addEventListener("turbo:load", function () {
  // Open first <details> for each section (without causing scroll)
  ["#experience-section", "#formations-section", "#projets-section"].forEach(id => {
    const section = document.querySelector(id);
    const first = section?.querySelector("details");
    if (first) first.setAttribute("open", "");
  });

  // Scroll into view only when user clicks a <summary>
  document.querySelectorAll("details summary").forEach(summary => {
    summary.addEventListener("click", () => {
      const parent = summary.parentElement;

      // Let toggle/animation settle
      setTimeout(() => {
        if (parent.open) {
          const offset = 80;
          const y = parent.getBoundingClientRect().top + window.scrollY - offset;

          window.scrollTo({
            top: y,
            behavior: "smooth"
          });
        }
      }, 250);
    });
  });
});
