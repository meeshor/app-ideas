# Postęp

Podsumowania kamieni milowych (sesja autonomiczna). Stan końcowy i uczciwa ocena — na końcu pliku.

## M0 — Szkielet ✅

- Vite 8 + React 19 + TypeScript 6 (strict, `noUncheckedIndexedAccess`), Vitest 5, Playwright 1.63 (preinstalowany Chromium, emulacja Pixel 7), ESLint 10 + typescript-eslint.
- Reguła ESLint pilnuje, by `src/core/` nie importował Reacta/IndexedDB i nie używał `window`/`document`.
- `vite-plugin-pwa` (generateSW, autoUpdate), manifest PL, ikony PNG renderowane z SVG skryptem `scripts/make-icons.mjs`.
- Skrypty: `dev`, `test`, `build`, `preview`, `e2e`, `lint`, `data`. README z instrukcją lokalną i na telefon.
- Sprawdzone: `npm test` (1 test dymny), `npm run build`, `npm run e2e` (1 test dymny), `npm run lint` — zielone.

## M1 — Rdzeń ✅

- Model danych w `src/core/types.ts` (Food + wariant przez `parentId`, Dish ze składnikami opcjonalnymi, Modifiers, LogEntry, UserOverride, Settings).
- Dane startowe od razu w skali M4: **213 produktów (w tym 42 warianty), 48 dań**, modyfikatory rozmiaru/ilości, 30 jednostek z formami, liczebniki. Źródło: `data-src/*.ts` → `npm run data` → `data/*.json`.
- Formy odmiany generowane regułami końcówek (`src/core/inflect.ts`, ~10 tys. form) + ręczne poprawki form nieregularnych w danych.
- Wszystkie wartości odżywcze **przybliżone, `verified: false`**, z polem `source`. Test spójności energii (4/4/9 kcal/g ± 25%) wyłapał już jeden błąd (kakao w proszku liczone z błonnikiem).
- Kalkulator z rozbiciem: „bułka żytnia 1 szt. (duża: 80 g) = 80 g → 200 kcal”, mnożnik globalny tylko gdy produkt nie ma gramów klasy rozmiaru.
- Cele: Mifflin-St Jeor × aktywność × korekta celu, podział makro, ręczne nadpisanie.
- Testy: 44 (text, inflect, dane, kalkulator, cele, historia, kopia zapasowa).
- Nie sprawdzone: realna trafność liczb względem tabel — brak dostępu do źródeł w tej sesji.
