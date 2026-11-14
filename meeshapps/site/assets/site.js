// meeshApps — przełącznik języka (PL/EN). Wybór zapamiętywany lokalnie, jeśli przeglądarka pozwala.
(function () {
  var root = document.documentElement;
  function load(key) { try { return localStorage.getItem(key); } catch (e) { return null; } }
  function save(key, val) { try { localStorage.setItem(key, val); } catch (e) {} }

  var params = new URLSearchParams(location.search);
  var lang = params.get("lang") || load("meesh-lang") ||
    ((navigator.language || "pl").toLowerCase().indexOf("pl") === 0 ? "pl" : "en");

  function setLang(l) {
    root.setAttribute("data-lang", l);
    root.setAttribute("lang", l);
    save("meesh-lang", l);
  }
  setLang(lang);

  document.addEventListener("DOMContentLoaded", function () {
    document.querySelectorAll("[data-set-lang]").forEach(function (b) {
      b.addEventListener("click", function () { setLang(b.getAttribute("data-set-lang")); });
    });
    document.querySelectorAll("[data-year]").forEach(function (el) {
      el.textContent = new Date().getFullYear();
    });
  });
})();
