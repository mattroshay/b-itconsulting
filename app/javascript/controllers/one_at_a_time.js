document.addEventListener("turbo:load", function () {
  function activateOneAtATime(containerSelector) {
    const container = document.querySelector(containerSelector);
    if (!container) return;

    const detailsList = container.querySelectorAll("details");

    detailsList.forEach(detail => {
      detail.addEventListener("toggle", () => {
        if (detail.open) {
          // Close others
          detailsList.forEach(other => {
            if (other !== detail) other.open = false;
          });

          // Scroll the summary back into view (after toggle)
          setTimeout(() => {
            detail.querySelector("summary")?.scrollIntoView({ behavior: "smooth", block: "start" });
          }, 100); // Delay lets layout settle first
        }
      });
    });
  }

  activateOneAtATime(".experience");
  activateOneAtATime(".formations");
  activateOneAtATime(".projets-futurs");
});
