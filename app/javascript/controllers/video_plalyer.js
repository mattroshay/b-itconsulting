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
