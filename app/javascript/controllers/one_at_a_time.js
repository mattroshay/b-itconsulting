document.addEventListener("turbo:load", function () {

  function activateOneAtATime(containerSelector) {
    const container = document.querySelector(containerSelector);
    if (!container) return;

    const detailsList = container.querySelectorAll("details");

    detailsList.forEach(detail => {
      detail.addEventListener("toggle", () => {
        if (detail.open) {
          detailsList.forEach(other => {
            if (other !== detail) other.open = false;
          });
        }
      });
    });
  }

  activateOneAtATime(".experience");
  activateOneAtATime(".formations");
  activateOneAtATime(".projets-futurs");
});
