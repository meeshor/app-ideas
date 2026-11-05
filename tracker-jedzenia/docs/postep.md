# Postęp

Podsumowania kamieni milowych (sesja autonomiczna). Stan końcowy i uczciwa ocena — na końcu pliku.

## M0 — Szkielet ✅

- Vite 8 + React 19 + TypeScript 6 (strict, `noUncheckedIndexedAccess`), Vitest 5, Playwright 1.63 (preinstalowany Chromium, emulacja Pixel 7), ESLint 10 + typescript-eslint.
- Reguła ESLint pilnuje, by `src/core/` nie importował Reacta/IndexedDB i nie używał `window`/`document`.
- `vite-plugin-pwa` (generateSW, autoUpdate), manifest PL, ikony PNG renderowane z SVG skryptem `scripts/make-icons.mjs`.
- Skrypty: `dev`, `test`, `build`, `preview`, `e2e`, `lint`, `data`. README z instrukcją lokalną i na telefon.
- Sprawdzone: `npm test` (1 test dymny), `npm run build`, `npm run e2e` (1 test dymny), `npm run lint` — zielone.
