document.addEventListener("DOMContentLoaded", function (event) {
  document.body.addEventListener('ajax:success', function (event) {
    var span = document.getElementById("results");
    span.textContent = event.detail[0];
  })
});
