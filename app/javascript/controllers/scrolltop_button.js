
//scrolltop-button
document.addEventListener("turbo:load", function () {
  const scrollTop = document.getElementById("scrollTop");
  if (!scrollTop) return;

  window.onscroll = function () {
    if (document.documentElement.scrollTop > 100) {
      scrollTop.classList.add("show");
    } else {
      scrollTop.classList.remove("show");
    }
  };

  scrollTop.addEventListener("click", function () {
    // Step 1: Close all <details> first
    closeAllDetails(".experience");

    // Step 2: Scroll to top
    window.scrollTo({ top: 0, behavior: "smooth" });

    // Step 3: Wait for scroll to finish, then reopen first detail
    const waitForTop = setInterval(() => {
      if (window.scrollY <= 5) {
        clearInterval(waitForTop);
        reopenFirstDetails(".experience");
      }
    }, 50);
  });

  function closeAllDetails(selector) {
    const section = document.querySelector(selector);
    if (!section) return;
    section.querySelectorAll("details").forEach(detail => detail.open = false);
  }

  function reopenFirstDetails(selector) {
    const section = document.querySelector(selector);
    if (!section) return;

    const detailsList = section.querySelectorAll("details");
    if (detailsList.length > 0) {
      const firstDetail = detailsList[0];
      const summary = firstDetail.querySelector("summary");

      // temporarily remove scroll-margin
      if (summary) summary.classList.add("no-scroll-margin");

      firstDetail.open = true;

      // restore after layout settles
      setTimeout(() => {
        if (summary) summary.classList.remove("no-scroll-margin");
      }, 200);
    }
  }
});
//scrolltop-button end
