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

## M2 — Parser ✅

- `RuleParser` (słownik + reguły, bez AI) za interfejsem `Parser` (gotowym na przyszły parser LLM zwracający tylko strukturę).
- Najdłuższe dopasowanie aliasu przed podziałem na pozycje, sygnatury dań (produkt/wariant + dodatki → danie), dodatki „z/ze/na”, „bez X”, „dużo X”, ilości przed i po nazwie, dopasowanie bez polskich znaków i z literówkami (OSA), podpowiedź posiłku.
- **116 przypadków w tabeli** + 6 testów własności (determinizm, rozbicie jak w specyfikacji, „bez masła”, pierwszeństwo definicji użytkownika, nowe danie użytkownika, wydajność). Razem w projekcie: 167 testów, wszystkie zielone.
- Raport: [`parser.md`](parser.md) — 11 znanych braków (m.in. „i sałata” bez ogonków, liczebniki złożone).
- Wydajność: budowa słownika ~70 ms przy starcie, parsowanie typowego wpisu 0–5 ms (pierwsze wywołania wolniejsze).

## M3 — Grywalny prototyp ✅

- Ekran „Dziś”: pole „Co zjadłeś?”, podgląd na żywo (rozbicie każdej pozycji na składniki z gramami i kcal), sumy i paski kcal/B/W/T względem celu, wpisy pogrupowane po posiłkach, nawigacja po dniach.
- Edycja pozycji w podglądzie: ilość, jednostka (porcje produktu + g/ml), rozmiar, zamiana produktu z listy podpowiedzi, edycja składu (ilość/jednostka/usuń/dodaj składnik).
- Zapis do IndexedDB (`idb`): wpis przechowuje oryginalny tekst, pozycje po poprawkach i wyliczenie z chwili zapisu; „Przelicz ponownie” liczy według aktualnej bazy.
- Niezrozumiane fragmenty podświetlone z przyciskiem „+ dodaj produkt”.
- E2E (Playwright, Chromium, Pixel 7): scenariusz z promptu „duża bułka żytnia z szynką” → zapis → widoczna suma (+ trwałość po przeładowaniu), edycja ilości, dodanie nieznanego produktu — 3/3 zielone.

## M4 — MVP ✅

- **Baza startowa**: 214 produktów (42 warianty) w 12 kategoriach, 48 dań, 30 jednostek, modyfikatory rozmiaru i ilości.
- **Historia**: lista dni z sumami i paskiem względem celu, średnia z ostatnich 7 dni (tylko dni z wpisami), przejście do dnia.
- **Baza**: przeglądanie i wyszukiwanie produktów/wariantów/dań, edycja (makro, porcje, porcja domyślna, gramy rozmiarów, porcja jako dodatek, aliasy — formy odmiany generują się same), dodawanie, oznaczenia „zmienione”/„moje”, „Przywróć domyślne”. Modyfikatory: mnożniki ilości i wartości zapasowe jednostek.
- **Osobiste definicje**: „★ Zapamiętaj jako moje” w podglądzie. Nazwa dania z poprawkami („bułka z szynką bez masła”, 3 plastry) → Twoja wersja tego dania; inny opis (wariant, dodatki) → nowe danie z aliasem równym opisowi (bez przejmowania innych opisów).
- **Ustawienia**: profil → Mifflin-St Jeor × aktywność × cel, podział makro %, cele ręczne, mnożniki rozmiarów, motyw jasny/ciemny/systemowy, eksport/import JSON (z walidacją), reset danych.
- **Szybkie ponawianie**: „Ostatnie” i „Częste” jako przyciski pod polem wpisu (dodają zapisane pozycje przeliczone na aktualnej bazie).
- **PWA**: manifest, ikony, service worker (precache całej aplikacji z bazą), działa offline — sprawdzone w e2e (`context.setOffline`).
- Zrzuty: [`screenshot-dzis.png`](screenshot-dzis.png), [`screenshot-dzis-ciemny.png`](screenshot-dzis-ciemny.png) (390 px, telefon).

---

# Stan końcowy — uczciwie

## Wyniki testów (ostatnie uruchomienie przed commitem M4)

| Sprawdzenie | Wynik |
|---|---|
| `npm test` (Vitest) | **173 / 173** zielone w 8 plikach; w tym **116 przypadków tabeli parsera** + 6 testów własności parsera |
| `npm run e2e` (Playwright, Chromium, emulacja Pixel 7) | **8 / 8** zielone |
| `npm run lint` (ESLint + reguła czystości `core/`) | 0 błędów, 0 ostrzeżeń |
| `npm run build` (tsc strict + Vite + PWA) | OK; JS 608 kB (150 kB gzip), z czego ~2/3 to baza produktów z formami odmiany |

## Co działa

- Pełna ścieżka: opis zdaniem → podgląd z rozbiciem „skąd ta liczba” → poprawki → zapis → sumy dnia i cele → historia.
- Deterministyczny parser z wariantami, rozmiarami, liczebnikami, „z/ze/na X”, „bez X”, „dużo X”, wieloma pozycjami, bez polskich znaków i z literówkami.
- Wszystkie warstwy danych edytowalne i przywracalne; własne definicje mają pierwszeństwo.
- Offline, bez kont, dane w IndexedDB, eksport/import.

## Czego nie ma / co nie działa albo nie zostało sprawdzone

- **Wartości odżywcze nie są zweryfikowane** z tabelami NIZP-PZH ani USDA (brak dostępu do źródeł w tej sesji): to przybliżenia z pamięci, wszystkie `verified: false`. Jedyna kontrola to test spójności 4/4/9 kcal (±25%), który wyłapał jeden błąd. **To największe ryzyko merytoryczne** — przed realnym użyciem warto przejrzeć wartości choćby 50 najczęstszych produktów.
- Masy porcji i składy dań („bułka z szynką” = 2 plastry + 5 g masła) to rozsądne domysły do strojenia.
- **Znane braki parsera** (szczegóły w [`parser.md`](parser.md)): „i sałata” bez polskich znaków nie dokleja się jako dodatek; mianownik po „i” zawsze tworzy nową pozycję; brak liczebników złożonych („dwadzieścia”, „sto”); odmiana z reguł bywa niepełna dla form nieregularnych; „pół X” liczone od porcji domyślnej; „na wodzie”/„z grilla” tylko gdy są w aliasach lub na liście wypełniaczy; zawartość tłuszczu („3,2%”) ignorowana.
- Nie testowane na fizycznym telefonie ani w Safari/iOS (tylko Chromium z emulacją Pixel 7). Instalacja PWA na ekran główny nie była sprawdzana ręcznie.
- Edycja wpisu po zapisie: można zmienić posiłek, przeliczyć lub usunąć — ale nie edytować pozycji (trzeba usunąć i dodać ponownie).
- Brak wykresów historii (jest lista dni i średnia tygodniowa) i brak wyszukiwania kodem kreskowym (poza zakresem MVP).
- Import JSON **zastępuje** dane (z potwierdzeniem), nie scala.
- Pakiet 608 kB JS: pierwsze wczytanie na słabym łączu może trwać chwilę; potem offline z cache.

## Co warto przetestować ręcznie na telefonie

1. Instalacja PWA (Android: „Zainstaluj aplikację”; iOS: „Do ekranu początk.”) i uruchomienie w trybie samolotowym.
2. Pisanie na klawiaturze ekranowej: czy podgląd nie „skacze”, czy Enter zapisuje (na iOS Enter w polu wieloliniowym może się zachowywać inaczej — jest też przycisk „Zapisz”).
3. Dyktowanie głosem do pola tekstowego (systemowa klawiatura) — parser dostaje wtedy tekst z interpunkcją i wielkimi literami.
4. Własne typowe posiłki: ile wpisów trafia od razu, a ile wymaga poprawki; czy „Zapamiętaj jako moje” zachowuje się zgodnie z oczekiwaniem.
5. Tryb ciemny systemu, duża czcionka systemowa (Dostępność), szerokość 360 px.
6. Eksport JSON na telefonie (pobieranie pliku) i import na innym urządzeniu.
7. Zmiana daty (wpis „na wczoraj”) i przejście przez północ.
