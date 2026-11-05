# Parser „Zjadłem” — co rozumie, czego nie, typowe błędy

Kod: [`src/core/parser.ts`](../src/core/parser.ts) (`RuleParser`), słownik: [`src/core/lexicon.ts`](../src/core/lexicon.ts),
testy: [`src/core/parser.test.ts`](../src/core/parser.test.ts) — **116 przypadków w tabeli + 6 testów własności**.

Parser zamienia tekst na strukturę `{matchedId, kind, quantity, unit, size, modifiers, factor, confidence, fragment, changes}`
plus listę niezrozumianych fragmentów. Liczb nie wylicza — robi to `calculator.ts` z bazy aplikacji.
Ten sam tekst i ta sama baza dają zawsze ten sam wynik (test „jest deterministyczny”).

## Jak działa (w skrócie)

1. **Normalizacja**: małe litery, interpunkcja → separatory, „200g” → „200 g”, „2,5” → 2,5, „x2” → 2, „mleko 2%” → „mleko”.
   Każde słowo ma klucz bez polskich znaków, więc „bulka z szynka” działa (z pewnością 0,95).
2. **Najdłuższe dopasowanie nazwy** w danym miejscu (do 6 słów), także przez „z” i „i”
   („pierogi z kapustą i grzybami”), dopiero potem separatory („,”, „+”, „i”, „oraz”, „plus”, nowa linia…) dzielą pozycje.
3. **Przed nazwą**: liczby („2”, „2,5”, „1/2”, „2 i pół”), liczebniki („dwie”, „pół”, „półtorej”, „kilka” = 3),
   jednostki („szklanka”, „łyżka”, „plaster”, „g”, „ml”, „talerz”, „cała” = sztuka…), rozmiar („duża”), ilość („dużo”, „trochę”).
4. **Po nazwie**: rozmiar („bułka duża”), ilość z jednostką („ryż 150 g”, „lody 2 gałki”), dodatki „z/ze/na X”, „bez X”.
5. **Kontynuacje po separatorze**: „…z szynką **i serem**” (narzędnik → dodatek), „…**, bez masła**”, „…**, dużo masła**”
   (jeśli masło jest w pozycji), „…**, 2 sztuki**”.
6. **Sygnatura dania**: produkt główny (albo jego wariant) + dodatki → danie o największej liczbie dopasowanych składników.
   „Duża bułka żytnia z szynką i serem” = danie „bułka z szynką i serem”, bułka podmieniona na żytnią, rozmiar dla bułki.
   Dodatki spoza dania są dopisywane z porcją „dodatkową” produktu (np. ser: 1 plaster, pomidor: 2 plastry).
7. **Literówki**: odległość Damerau-Levenshteina (OSA) — 1 dla słów 4–7 liter, 2 dla dłuższych, krótszych nie poprawiamy.
   Pewność 0,6. Dłuższe dopasowanie przybliżone może zastąpić krótsze dokładne tylko, gdy pierwsze słowo się zgadza
   („bułka żytna” → „bułka żytnia”), żeby „kawa z cukrem” nie stało się „kakao z cukrem”.
8. **Osobiste definicje** (rekordy użytkownika) wygrywają remisy w słowniku i przy wyborze dania.

## Co rozumie (przykłady z testów)

| Wejście | Wynik |
|---|---|
| `duża bułka żytnia z szynką` | danie *bułka z szynką*, wariant *bułka żytnia*, rozmiar duża (80 g z danych produktu) |
| `bułka żytnia z szynką i serem` | danie *bułka z szynką i serem* + wariant |
| `bułka z szynką drobiową` | wariant dodatku (szynka drobiowa) |
| `bułka z 3 plastrami szynki` | zmiana ilości składnika dania |
| `bułka z szynką, bez masła` / `… bez masła` | usunięcie składnika domyślnego |
| `bułka żytnia z szynką, dużo masła` | masło × 2 |
| `bułka z dużą ilością masła` | danie *bułka z masłem*, masło × 2 |
| `2 jajka i kawa z mlekiem` | 2 pozycje |
| `zupa pomidorowa oraz 2 kotlety mielone`, `jajecznica + kawa + sok`, `kawa 2 jajka` | podział na pozycje |
| `jajecznica z 4 jajek`, `płatki owsiane z mlekiem` (→ owsianka) | ilość w daniu, sygnatura |
| `3 kromki chleba z masłem i miodem` | danie *kanapka* × 3 + miód |
| `pół szklanki mleka`, `1/2 tabliczki czekolady`, `2 i pół bułki`, `półtorej bułki` | ułamki i liczebniki |
| `200g ryżu`, `ryż 150 g`, `piwo 0,5 l`, `250 ml kefiru`, `bułka x2` | ilości przed i po nazwie |
| `2 pączki` vs `paczka chipsów` | „pączki” to produkt, „paczka” to jednostka (rozróżnienie po polskich znakach) |
| `bulka z szynka`, `duza bulka zytnia z szynka`, `zolty ser` | bez polskich znaków |
| `bułak`, `jajecznca`, `spagetti bolonese` | literówki (pewność 0,6) |
| `na śniadanie owsianka`, `obiad: rosół z makaronem` | podpowiedź posiłku |
| `bułka z kawiorem` | bułka + niezrozumiane „kawiorem” |

## Czego nie rozumie / znane braki

1. **Bez polskich znaków „i X” po „z …” jest nierozpoznawalne jako dodatek**: „bulka z szynka i salata” daje
   bułkę z szynką + osobną sałatę (porcja domyślna), bo „salata” może być mianownikiem. Z ogonkami („i sałatą”) działa.
2. **Mianownik po „i”** jest zawsze nową pozycją: „bułka z szynką i ser” → bułka z szynką + ser (porcja domyślna).
   Zwykle zgodne z intencją, ale nie zawsze.
3. **Odmiana z reguł** jest przybliżona: generuje też formy nieistniejące (nieszkodliwe), a może pominąć nieregularne
   (np. „pierś” → „piersi” trzeba było dopisać ręcznie). Nowy produkt dodany w UI dostaje formy z tych samych reguł.
4. **„na wodzie”, „w bułce”, „z grilla”** — sposób przygotowania rozumiany tylko, jeśli jest w aliasie
   („owsianka na wodzie”, „kebab w bułce”) albo słowo jest na liście wypełniaczy (grill, piekarnik, patelnia).
5. **Brak liczebników złożonych** („dwadzieścia”, „sto pięćdziesiąt gramów”) — działają cyfry i liczebniki 1–10.
6. **„dużo X” po przecinku** modyfikuje poprzednią pozycję tylko, gdy X już w niej jest; inaczej jest nową pozycją ×2.
7. **Dwuznaczne „pół”**: „pół pizzy” = pół porcji domyślnej (u pizzy: pół całej, 225 g). Dla produktów z porcją
   „kawałek” wynik może nie odpowiadać intencji.
8. **„bez X” bez poprzedniej pozycji** („bez cukru” na początku) trafia do niezrozumianych, a gdy X nie ma w pozycji —
   zapisywane w modyfikatorach, ale nic nie zmienia.
9. **„kilka”, „parę”** to umowne 3 i 2.
10. **Długi ogon**: rzeczy spoza ~210 produktów i ~50 dań trafiają do „niezrozumianych” — wtedy w UI jest przycisk
    „dodaj nowy produkt”. Dopasowanie przybliżone potrafi wtedy trafić w coś podobnego z obniżoną pewnością
    (warto patrzeć na znacznik „literówka?” w podglądzie).
11. **Zawartość tłuszczu w tekście** („mleko 3,2%”) jest ignorowana — wybór wariantu tylko po nazwie („mleko pełne”).

## Typowe błędy i jak je poprawić w aplikacji

- Zły produkt (np. „sok” → pomarańczowy): w podglądzie kliknij pozycję → „Produkt” → wybierz inny.
- Złe ilości w daniu: edytuj składniki → **„Zapamiętaj jako moje”** — od tej pory ten opis daje Twój skład.
- Brakujące słowo: „dodaj nowy produkt” przy niezrozumianym fragmencie (formy odmiany tworzą się automatycznie).

## Pomysł na przyszłość: parser LLM

Interfejs `Parser { id; parse(text) }` przyjmuje także `Promise<ParseResult>`. Parser LLM miałby zwracać wyłącznie
strukturę (id produktów z bazy, ilości, jednostki) — liczby nadal liczy kalkulator z bazy, więc przejrzystość zostaje.
Naturalny tryb: reguły najpierw, LLM tylko dla fragmentów z listy „niezrozumianych”.
