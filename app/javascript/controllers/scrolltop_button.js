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
    closeAllDetails(".experience");
    window.scrollTo({ top: 0, behavior: "smooth" });

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
    section.querySelectorAll("details").forEach(d => d.removeAttribute("open"));
  }

  function reopenFirstDetails(selector) {
    const section = document.querySelector(selector);
    if (!section) return;

    const firstDetail = section.querySelector("details");
    if (firstDetail) firstDetail.setAttribute("open", "");
  }
});
