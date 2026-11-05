# Plan: „Zjadłem” (MVP M0–M4)

Źródło wymagań: [`../../prompty/04-tracker-jedzenia.md`](../../prompty/04-tracker-jedzenia.md), tło: [`../../analiza-tracker-jedzenia.md`](../../analiza-tracker-jedzenia.md).
Sesja autonomiczna: plan nie czeka na akceptację, postęp po każdym kamieniu w [`postep.md`](postep.md).

## Struktura katalogów

```
tracker-jedzenia/
  data-src/        źródła danych startowych w TS (zwięzły zapis: produkt, makro na 100 g, porcje)
  scripts/         build-data.ts: data-src → data/*.json (z formami odmiany), ikony PWA
  data/            foods.json, dishes.json, modifiers.json — dane domyślne wczytywane przez aplikację
  src/core/        czysty TS, bez Reacta i przeglądarki (pilnuje tego reguła ESLint)
    types.ts       model danych: Food (+Variant przez parentId), Dish, Modifiers, LogEntry, UserOverride, Settings
    config.ts      wszystkie stałe (progi, pewności, godziny posiłków, współczynniki) z opisem pochodzenia
    text.ts        normalizacja, usuwanie polskich znaków, tokenizacja, liczby
    inflect.ts     półautomatyczne formy odmiany (reguły końcówek) — używane przez skrypt danych i przy dodawaniu produktu w UI
    fuzzy.ts       odległość Damerau-Levenshteina (OSA)
    db.ts          scalanie: dane domyślne + UserOverride; dziedziczenie wariantów; „rodziny” produktów
    lexicon.ts     indeks aliasów/form (bez polskich znaków), jednostek, liczebników, modyfikatorów
    parser.ts      interfejs Parser + RuleParser (słownik + reguły)
    calculator.ts  pozycja → gramy → makro, z czytelnym rozbiciem („bułka 60 g × 1,2 (duża) = 72 g → …”)
    goals.ts       Mifflin-St Jeor × aktywność, cel, podział makro
    meals.ts, stats.ts, backup.ts, format.ts
  src/storage/     IndexedDB (idb): wpisy, nadpisania użytkownika, ustawienia
  src/ui/          React, cienka warstwa: Dziś, Historia, Baza, Ustawienia
  e2e/             Playwright (Chromium, emulacja telefonu)
  docs/            plan.md, postep.md, parser.md, zrzut ekranu
```

Odstępstwo od promptu: rdzeń leży w `src/core/` (a nie w `core/` w korzeniu), żeby Vite/TS miały jeden katalog źródeł. Plik testów parsera: `src/core/parser.test.ts`.

## Kluczowe typy (skrót)

- `Food { id, name, parentId?, per100?: Macros, portions?: Record<unit, g>, defaultPortion?, sizes?: {small, standard, large} (g porcji domyślnej), addon?: {qty, unit} (porcja jako dodatek „z X”), density?, aliases, forms, source, verified }` — wariant to `Food` z `parentId`, dziedziczy brakujące pola.
- `Dish { id, name, aliases, forms, ingredients: {foodId, qty, unit, optional?}[], main?: index, sizeMode: 'main'|'all' }` — `optional` = składnik domyślny, który można wyłączyć („bez masła”).
- Sygnatura dania = (składnik główny, zbiór nieopcjonalnych składników dodatkowych). Dzięki temu „bułkę żytnią z szynką i serem” rozpoznajemy jako danie „bułka z szynką i serem” z podmienionym wariantem bułki, bez wpisywania wszystkich kombinacji jako aliasów.
- `ParsedItem { kind, matchedId, quantity, unit, size, modifiers, confidence, fragment, mainVariantId?, changes[], ingredients? }`, `ParseResult { items, unknown[], mealHint? }`.
- `Parser { id; parse(text): ParseResult | Promise<ParseResult> }` — miejsce na przyszły parser LLM (tekst → ta sama struktura); liczby zawsze liczy `calculator.ts` z bazy aplikacji.
- `LogEntry { id, date, time, meal, text, items: ParsedItem[], computed, totals }` — zapisujemy wynik, nie tylko tekst; „przelicz ponownie” liczy zapisane pozycje na aktualnej bazie.
- `UserOverride { key: 'food:id'|'dish:id'|'modifiers', kind, id, data, isNew, updatedAt }` — nakładka na dane domyślne, przywracalna.

## Kolejność prac

1. M0: Vite + React + TS strict, Vitest, Playwright, ESLint, skrypty, README.
2. M1: typy, dane startowe (od razu celuję w ~150 produktów i ~40 dań), generator form, kalkulator, cele, testy.
3. M2: parser + ≥ 60 przypadków testowych + `docs/parser.md`.
4. M3: ekran „Dziś” z podglądem, edycją pozycji i zapisem do IndexedDB; e2e „duża bułka żytnia z szynką”.
5. M4: historia, baza (edycja/przywracanie), „zapamiętaj jako moje”, ustawienia i cele, eksport/import, PWA offline, szybkie ponawianie.

## Ryzyka

- **Odmiana polska** bez biblioteki lematyzacji: reguły końcówek przegenerowują formy (to akceptowalne), ale mogą powodować kolizje między produktami — test danych wykrywa kolizje kluczy i wymusza ich jawne rozstrzygnięcie.
- **„i” jako separator vs łącznik dodatków** („bułka z szynką i serem”): heurystyka narzędnika (-em, -ą, -ami) po „z”. Bez polskich znaków „szynka/szynką” są nierozróżnialne — znany brak.
- **Wartości odżywcze**: przybliżone z pamięci typowych tabel (NIZP-PZH/USDA), bez weryfikacji źródłowej → wszystkie `verified: false`.
- **Nowe wersje narzędzi** (Vite 8, Vitest 5, ESLint 10): ryzyko niekompatybilności wtyczek; w razie problemów cofam do starszych.
- Dokładność opisu słownego to ±20–30% — komunikowane w UI.
