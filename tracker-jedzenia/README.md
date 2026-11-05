# Zjadłem — prosty, przejrzysty tracker jedzenia

Wpisujesz zwykłym polskim zdaniem, co zjadłeś („duża bułka żytnia z szynką”, „2 jajka i kawa z mlekiem”),
a aplikacja szacuje kalorie, węglowodany, białko i tłuszcze — **deterministycznie i z widocznym rozbiciem**,
skąd wzięła się każda liczba. Każdą liczbę da się poprawić i zapamiętać jako własną definicję.

- Bez AI, bez kont, bez backendu. Dane tylko w przeglądarce (IndexedDB), eksport/import JSON.
- PWA: działa offline, da się zainstalować na telefonie.
- Wartości są **orientacyjne** (szacunek opisu słownego to typowo ±20–30%). To nie jest porada medyczna.

Dokumentacja: [plan](docs/plan.md) · [postęp i stan](docs/postep.md) · [parser: co rozumie, czego nie](docs/parser.md).

## Uruchomienie lokalnie

Wymagany Node 20+ (testowane na 22).

```bash
cd tracker-jedzenia
npm install
npm run dev        # serwer deweloperski, http://localhost:5173
npm test           # testy jednostkowe (Vitest): rdzeń, parser, dane
npm run build      # typecheck + build produkcyjny do dist/ (z service workerem)
npm run preview    # podgląd buildu, http://localhost:4173
npm run e2e        # scenariusze Playwright (uruchamia preview sam)
npm run lint       # ESLint
npm run data       # przebudowa data/*.json z data-src/*.ts (formy odmiany)
```

Playwright używa Chromium; jeśli nie masz go lokalnie: `npx playwright install chromium`.

## Na telefonie (instalacja PWA)

Service worker działa tylko na `localhost` albo przez HTTPS.

1. Najprościej: zbuduj (`npm run build`) i wystaw `dist/` na dowolnym statycznym hostingu z HTTPS
   (GitHub Pages, Netlify, Cloudflare Pages). Build używa względnych ścieżek, więc działa też z podkatalogu.
2. W sieci lokalnej do szybkiego podglądu: `npm run dev -- --host` i otwórz adres IP komputera na telefonie
   (bez HTTPS aplikacja działa, ale nie będzie offline ani instalowalna).
3. Instalacja: Android/Chrome — menu ⋮ → „Zainstaluj aplikację” / „Dodaj do ekranu głównego”;
   iPhone/Safari — Udostępnij → „Do ekranu początk.”.
4. Po pierwszym otwarciu aplikacja działa bez sieci. Dane zostają na urządzeniu — rób eksport JSON
   (Ustawienia), jeśli chcesz mieć kopię albo przenieść dane na inne urządzenie.

## Jak to działa (w skrócie)

- `data/` — baza startowa: produkty (wartości na 100 g, porcje nazwane, gramy dla rozmiarów), warianty
  (`parentId`), dania złożone, modyfikatory, jednostki i liczebniki. Źródło edycji: `data-src/*.ts`,
  potem `npm run data` generuje JSON razem z formami odmiany.
- `src/core/` — czysty TypeScript: parser (słownik + reguły), kalkulator, cele (Mifflin-St Jeor).
  Interfejs `Parser` pozwala później dołożyć parser LLM *tylko* do zamiany tekstu na strukturę — liczby
  zawsze pochodzą z bazy aplikacji.
- `src/ui/` — cienka warstwa React; `src/storage/` — IndexedDB.
