//scrolltop-button
document.addEventListener("turbo:load", function () {
  var scrollTop = document.getElementById("scrollTop");

  if (!scrollTop) return; // safeguard in case the button doesn't exist on the page

  window.onscroll = function () {
    if (document.documentElement.scrollTop > 100) {
      scrollTop.classList.add("show");
    } else {
      scrollTop.classList.remove("show");
    }
  };

  scrollTop.addEventListener("click", function () {
    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  });
});

//scrolltop-button end
