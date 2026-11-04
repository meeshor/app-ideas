# Prompt startowy: „Zjadłem” — prosty, przejrzysty tracker jedzenia

> Skopiuj wszystko poniżej linii do nowej sesji Claude Code. Analiza pomysłu: [`../analiza-tracker-jedzenia.md`](../analiza-tracker-jedzenia.md).

---

Budujemy aplikację **„Zjadłem”** (nazwa robocza): prosty tracker jedzenia, w którym użytkownik **wpisuje zwykłym polskim zdaniem, co zjadł** („bułka z szynką”, „duża bułka żytnia z szynką i serem”, „2 jajka i kawa z mlekiem”), a aplikacja **szacuje kalorie, węglowodany, białko i tłuszcze** i pokazuje, ile zostało do dziennego celu.

## Cel produktu i wyróżnik

- Wpis posiłku ma trwać kilka sekund: jedno pole tekstowe, Enter, gotowe.
- **Deterministycznie i przejrzyście:** ten sam opis zawsze daje ten sam wynik, a przy każdym wpisie widać rozbicie, skąd wzięła się liczba, np. *bułka pszenna 60 g × 1,2 (duża) = 72 g → 198 kcal; szynka 2 plastry = 30 g → 33 kcal; masło 5 g → 37 kcal*.
- **Każdą liczbę da się poprawić**, a poprawka zostaje zapamiętana jako osobista definicja („moja bułka z szynką ma 3 plastry szynki i bez masła”).
- **Bez AI w MVP**: żadnych zdjęć, żadnego LLM. Parser oparty na słowniku i regułach. Zaprojektuj jednak interfejs `Parser` tak, żeby później dało się dołożyć opcjonalny LLM *wyłącznie jako parser* tekstu → struktura. Liczby zawsze pochodzą z bazy aplikacji.
- **Offline, prywatnie, bez kont i backendu.** Dane tylko w przeglądarce użytkownika, z eksportem i importem JSON.

## Platforma i stos

- **PWA** (działa na telefonie i komputerze, instalowalna, offline).
- TypeScript (strict), Vite, React. Stan i dane: IndexedDB (np. przez `idb` lub Dexie). Service worker przez `vite-plugin-pwa`.
- Testy: Vitest dla logiki, Playwright dla kilku scenariuszy end-to-end (Chromium jest dostępny w środowisku).
- Bez bibliotek UI-kombajnów. Prosty, czytelny CSS, tryb jasny i ciemny, układ pod telefon (od 360 px szerokości).
- **Rdzeń (`core/`) to czysty TypeScript bez zależności od Reacta i przeglądarki**: model danych, parser, kalkulator, cele. Ma być w pełni testowalny jednostkowo.

## Model danych (wymagany)

1. **`Food`** (produkt): `id`, nazwa, wartości na 100 g (kcal, węglowodany, białko, tłuszcz), **porcje nazwane** (np. `sztuka: 60 g`, `plaster: 15 g`, `łyżka: 10 g`), porcja domyślna, **gramy dla klas rozmiaru** (opcjonalnie: `mała`, `standard`, `duża`), źródło wartości (np. „tabele NIZP-PZH, wartość przybliżona”).
2. **`Variant`** (wariant): ta sama encja co `Food` z polem `parentId`. Nadpisuje tylko te pola, które podaje (np. „bułka żytnia” zmienia wartości na 100 g, a masę sztuki dziedziczy po „bułce”).
3. **`Dish`** (danie złożone, „przepis”): nazwa, aliasy, lista składników `{foodId, ilość, jednostka}`, opcjonalne składniki domyślne (np. masło), które użytkownik może wyłączyć. Przykład: „bułka z szynką” = 1 sztuka bułki + 2 plastry szynki + 5 g masła.
4. **`Modifier`** (modyfikator): słowa typu „mała”, „duża”, „ogromna”, „pół”, „dużo masła”, „bez masła”. Kolejność rozstrzygania rozmiaru: gramy klasy rozmiaru z produktu → **globalny mnożnik** z ustawień (domyślnie mała 0,8×, duża 1,2×, ogromna 1,5×, zmienialne).
5. **`Alias`**: każda nazwa ma listę form (odmiana, synonimy): „bułka, bułkę, bułki, bułek, kajzerka, bułeczka”. W MVP formy odmiany trzymaj jawnie w danych (generowane półautomatycznie prostymi regułami końcówek i ręcznie poprawione), zamiast ciągnąć ciężką bibliotekę lematyzacji.
6. **`LogEntry`**: data i czas, posiłek (śniadanie / obiad / kolacja / przekąska, zgadywany po godzinie, do zmiany), **oryginalny tekst**, wynik parsowania (lista pozycji z gramami), suma makro. Zapis wyniku, a nie tylko tekstu, żeby późniejsza zmiana bazy nie przepisywała historii (z opcją „przelicz ponownie”).
7. **`UserOverride`**: osobiste definicje i poprawki użytkownika, mające pierwszeństwo przed danymi domyślnymi.
8. **`Settings`**: profil (płeć, wiek, wzrost, waga, aktywność, cel: utrzymanie / redukcja / masa), mnożniki rozmiarów, cele makro.

Dane domyślne trzymaj w plikach JSON w repo (`data/foods.json`, `data/dishes.json`, `data/modifiers.json`), wczytywanych przy pierwszym uruchomieniu. Zacznij od **około 150 najczęstszych produktów i 40 dań typowych dla polskiej kuchni** (pieczywo, wędliny, sery, nabiał, jajka, warzywa, owoce, kasze, ryż, makaron, ziemniaki, mięsa, zupy, pierogi, napoje z mlekiem i cukrem…). Wartości odżywcze podawaj jako przybliżone, z polem `source`. **Nie zmyślaj precyzji:** gdzie nie masz pewnego źródła, wstaw rozsądne przybliżenie i oznacz `"verified": false`.

## Parser (najważniejsza część)

Wejście: dowolny tekst po polsku. Wyjście: lista pozycji `{matchedId, typ: food|dish, ilość, jednostka, rozmiar, modyfikatory, pewność, fragment tekstu}` oraz lista **niezrozumianych fragmentów**.

Kroki:
1. Normalizacja: małe litery, ujednolicenie spacji i interpunkcji. Dopasowanie także bez polskich znaków („bulka z szynka”).
2. Podział na pozycje po „i”, „,”, „+”, „oraz”, nowych liniach. **Uwaga:** „z” łączy składniki dania („bułka z szynką”), więc najpierw szukaj najdłuższego dopasowania dania w całym fragmencie, a dopiero potem rozbijaj.
3. Ilości: liczby („2”, „2,5”, „1/2”), liczebniki słowne („dwie”, „trzy”, „pół”, „półtora”), jednostki i porcje („szklanka”, „łyżka”, „plaster”, „g”, „ml”, „kawałek”, „talerz”, „miska”).
4. Rozmiar i modyfikatory przed lub po nazwie („duża bułka”, „bułka duża”, „bułka z dużą ilością masła”).
5. Dopasowanie nazwy: najdłuższe dopasowanie aliasu (wielowyrazowego), potem warianty („bułka żytnia” przed „bułka”), potem dopasowanie przybliżone (odległość Levenshteina z progiem) na literówki, z obniżoną pewnością.
6. Dania z dopiskami: „bułka z szynką i serem” = danie „bułka z szynką” + ser (domyślna porcja do kanapki) albo osobne danie, jeśli istnieje. „bez masła” usuwa składnik domyślny.
7. Osobiste definicje użytkownika mają pierwszeństwo.

**Testy parsera to podstawa jakości.** Przygotuj zestaw minimum **60 przypadków** w `core/parser.test.ts` (tabela wejście → oczekiwany wynik), w tym: odmiany, liczebniki, rozmiary, warianty, dania z dopiskami, „bez X”, literówki, brak polskich znaków, kilka pozycji w jednym zdaniu, tekst niezrozumiały, puste wejście.

## UI (MVP)

1. **Dziś:** pole „Co zjadłeś?” na górze, pod nim lista wpisów z dnia pogrupowana po posiłkach, sumy i paski postępu: kcal, B, W, T względem celu.
2. **Podgląd przed zapisem:** po wpisaniu tekstu, ale przed zatwierdzeniem, pokazuj rozbicie na pozycje z gramami i makro. Każdą pozycję można kliknąć i zmienić (ilość, rozmiar, inny produkt z listy podpowiedzi). Niezrozumiane fragmenty są podświetlone, z opcją „dodaj nowy produkt”.
3. **„Zapamiętaj jako moje”:** po poprawce możliwość zapisania jako osobistej definicji dania.
4. **Historia:** poprzednie dni, proste podsumowanie tygodnia (średnie kcal i makro).
5. **Baza:** przeglądanie i edycja produktów, wariantów, dań i modyfikatorów. Zmiany użytkownika są oznaczone i dają się przywrócić do wartości domyślnej.
6. **Ustawienia:** profil i cele (Mifflin-St Jeor × współczynnik aktywności, podział makro z możliwością ręcznej zmiany), mnożniki rozmiarów, eksport i import JSON, reset danych.
7. Szybkie ponawianie: lista ostatnich i częstych wpisów do dodania jednym dotknięciem.

Teksty w UI po polsku. Cele opisuj jako „orientacyjne”, z krótką informacją, że to szacunki, a nie porada medyczna.

## Kamienie milowe

1. **M0 — Szkielet:** projekt Vite + TS + React, Vitest, Playwright, ESLint, skrypty `npm run dev / test / build / e2e`, README.
2. **M1 — Rdzeń:** model danych, dane startowe (pierwsze ~50 produktów i ~15 dań), kalkulator makro, cele dzienne. Testy jednostkowe.
3. **M2 — Parser:** pełny parser z zestawem ≥ 60 testów. Raport w `docs/parser.md`: co rozumie, czego nie, typowe błędy.
4. **M3 — Grywalny prototyp:** ekran „Dziś” z podglądem i zapisem do IndexedDB, edycja pozycji. Scenariusz e2e: wpis „duża bułka żytnia z szynką” → zapis → widoczna suma.
5. **M4 — MVP:** pełna baza startowa, historia, edycja bazy, osobiste definicje, ustawienia, eksport i import, PWA offline.

Po każdym kamieniu krótko opisz, co działa, czego nie sprawdzono i co warto przetestować ręcznie na telefonie.

## Zasady pracy

- Zacznij od krótkiego planu (struktura katalogów, kluczowe typy, ryzyka) w `docs/plan.md`.
- Wszystkie stałe (mnożniki, progi dopasowania przybliżonego, domyślne porcje) trzymaj w danych lub w jednym pliku konfiguracyjnym, z komentarzem, skąd pochodzą, albo z oznaczeniem „do strojenia”.
- Rdzeń bez zależności od UI. UI cienkie.
- Krótkie commity z opisem. README z instrukcją uruchomienia lokalnie i na telefonie (instalacja PWA).
