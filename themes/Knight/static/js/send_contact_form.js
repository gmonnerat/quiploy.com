/*global jQuery, document, window */
(function ($, window, document) {
  "use strict";
  var csrftoken,
    get_token_url = atob("aHR0cHM6Ly9ldmVuaW5nLWhlYWRsYW5kLTgwODIxLmhlcm9rdWFwcC5jb20v"),
    url = atob("aHR0cHM6Ly9ldmVuaW5nLWhlYWRsYW5kLTgwODIxLmhlcm9rdWFwcC5jb20vc2VuZC8=");

  function init () {
    var request, strong, div;
    document.forms["contactForm"].addEventListener("submit", function(evt) {
      evt.preventDefault();
      request = new XMLHttpRequest();
      request.open("POST", url);
      request.withCredentials = true;
      request.send(new FormData(this));
      strong = document.createElement("strong");
      strong.innerText = "Sua mensagem foi enviada com sucesso.";
      div = document.getElementById("contactForm");
      div.innerHTML = "";
      div.appendChild(strong);
      return false;
    });
    request = new XMLHttpRequest();
    request.open("GET", get_token_url);
    request.send();
  }

  document.addEventListener("DOMContentLoaded", init, false);

}(jQuery, window, document));
