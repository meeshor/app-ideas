// meeshApps — język (PL/EN) i podgląd palet. Wybór zapamiętywany lokalnie, jeśli przeglądarka pozwala.
(function () {
  var root = document.documentElement;
  function load(key) { try { return localStorage.getItem(key); } catch (e) { return null; } }
  function save(key, val) { try { localStorage.setItem(key, val); } catch (e) {} }

  var params = new URLSearchParams(location.search);
  var lang = params.get("lang") || load("meesh-lang") ||
    ((navigator.language || "pl").toLowerCase().indexOf("pl") === 0 ? "pl" : "en");
  var palette = params.get("palette") || load("meesh-palette") || "ember";

  function setLang(l) {
    root.setAttribute("data-lang", l);
    root.setAttribute("lang", l);
    save("meesh-lang", l);
  }
  function setPalette(p) {
    root.setAttribute("data-palette", p);
    save("meesh-palette", p);
    document.querySelectorAll("[data-set-palette]").forEach(function (b) {
      b.setAttribute("aria-pressed", String(b.getAttribute("data-set-palette") === p));
    });
  }
  setLang(lang);
  root.setAttribute("data-palette", palette);

  document.addEventListener("DOMContentLoaded", function () {
    setPalette(palette);
    document.querySelectorAll("[data-set-lang]").forEach(function (b) {
      b.addEventListener("click", function () { setLang(b.getAttribute("data-set-lang")); });
    });
    document.querySelectorAll("[data-set-palette]").forEach(function (b) {
      b.addEventListener("click", function () { setPalette(b.getAttribute("data-set-palette")); });
    });
    var y = document.querySelectorAll("[data-year]");
    y.forEach(function (el) { el.textContent = new Date().getFullYear(); });
  });
})();
