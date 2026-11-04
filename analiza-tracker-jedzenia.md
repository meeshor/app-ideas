# Prosty tracker jedzenia — analiza pomysłu

Data: 2026-11-04

## Pomysł

Użytkownik wpisuje zwykłym zdaniem, co zjadł („bułka z szynką”, „duża bułka żytnia z szynką”), a aplikacja szacuje kalorie, węglowodany, białko i tłuszcze oraz pokazuje, ile zostało do dziennego celu. Bez rozpoznawania zdjęć i innych bajerów.

- Rozmiary („mała”, „duża” i inne stopniowania) działają jak przeliczniki.
- Produkt ma wartości domyślne („bułka”), a wariant („bułka żytnia”) ma własne, nadpisujące je wartości.
- Wszystkie parametry (współczynniki rozmiarów, wartości produktów, skład dań) da się konfigurować, ale mają rozsądne wartości domyślne.

## Konkurencja

Opisywanie posiłku słowami to w 2026 r. standard, a nie nowość.

| Aplikacja | Jak działa | Różnica względem pomysłu |
|---|---|---|
| **Fitatu** (PL, bardzo popularna) | Wyszukiwanie głosowe AI („powiedz, co zjadłeś”), szacowanie kaloryczności dania po nazwie w planie Premium+AI, rozpoznawanie zdjęć. | Najgroźniejszy konkurent w Polsce: zna polskie jedzenie, ma dużą bazę. Wynik to czarna skrzynka AI, funkcja jest płatna. |
| **Natural Macro, CalNotes, BitePad, Healthshape, Munchlog, Parsely, CrumbStream** | Opis tekstem lub głosem → kalorie i makro. Parsely przyjmuje nawet SMS-y. | Prawie wszystkie wysyłają tekst do LLM i pokazują wynik bez uzasadnienia. Ten sam opis potrafi dać różne liczby. Brak konfiguracji. |
| **MyFitnessPal, Lose It!, Cronometer, Yazio** | Klasycznie: wyszukaj produkt, podaj gramy. | Właśnie od nich ludzie odchodzą. |

**Czy są lubiane:** recenzje i porównania z 2026 r. zgodnie wskazują, że głównym powodem porzucania liczenia kalorii jest żmudne wpisywanie. Na MyFitnessPal narzeka się też na jakość bazy tworzonej przez użytkowników, rosnące paywalle i reklamy. Aplikacje z opisem tekstowym chwali się za wygodę, ale ich dokładności nikt niezależnie nie sprawdził. Większość porównań piszą twórcy konkurencyjnych aplikacji, więc to opinie, a nie twarde dane.

## Czym ten pomysł się realnie różni

To nie jest „tracker bez AI”, tylko **tracker z przejrzystym, deterministycznym modelem**:

1. **Ten sam opis = zawsze ten sam wynik**, z widocznym rozbiciem: *bułka pszenna 60 g × 1,2 (duża) + szynka 2 plastry (30 g) + masło 5 g*.
2. **Każdą liczbę da się poprawić**, a poprawka zostaje zapamiętana („moja bułka z szynką ma 3 plastry”). Po tygodniu używania większość wpisów trafia w punkt.
3. **Offline, bez abonamentu, bez wysyłania danych o jedzeniu na serwer.**

To realna przewaga dla osób, które nie ufają liczbom z AI albo chcą mieć kontrolę. Ale to nisza, nie masowy rynek.

## Wykonalność

### Łatwe

- **Dane:** polskie tabele składu i wartości odżywczej żywności (NIZP-PZH), USDA FoodData Central, Open Food Facts (produkty z kodem kreskowym).
- **Cele dzienne:** wzór Mifflin-St Jeor × współczynnik aktywności, podział na makro. Komunikować jako „orientacyjne cele”, nie zalecenia (unikamy porad medycznych).
- **Mnożniki, warianty, konfiguracja:** prosta logika.

### Trudne (tu jest cała praca)

1. **Rozumienie polskiego tekstu.** „bułkę z szynką”, „2 bułki z szynką i serem”, „kanapka z szynką”, „bułka żytnia z szynką, dużo masła”: odmiana, liczebniki, synonimy, literówki. Bez LLM potrzebny jest słownik form (aliasy / lematyzacja, np. Morfologik), synonimy i proste reguły gramatyczne. Na kilkaset najczęstszych produktów to wykonalne, na długi ogon nie.
   - **Kompromis:** warstwa 1 to słownik i reguły (deterministyczne). Warstwa 2 (opcjonalna, później) to mały LLM **wyłącznie jako parser** tekstu na strukturę `{produkt, wariant, rozmiar, ilość}`. Liczby zawsze pochodzą z bazy aplikacji, więc przejrzystość zostaje.
2. **Dania złożone i domyślne porcje.** Co znaczy „bułka z szynką”: ile plastrów, czy z masłem? Potrzebna baza „przepisów” z domyślnym składem. To praca redakcyjna, nie programistyczna.
3. **Mnożniki rozmiaru.** Jeden globalny przelicznik („duża = 1,2×”) sprawdzi się słabo: duża pizza i duża bułka to zupełnie inne różnice. Lepiej: produkt ma gramy dla klas *mała / standard / duża*, a globalny mnożnik to tylko wartość zapasowa.
4. **Dokładność.** Opis słowny zawsze da błąd rzędu ±20–30%. Do świadomego odżywiania wystarczy, do precyzyjnej redukcji nie. Trzeba to uczciwie komunikować.

## Ocena

| Kryterium | Ocena (1–5) | Komentarz |
|---|---|---|
| Wykonalność techniczna | ★★★★☆ | Prototyp to kilka tygodni po godzinach. Najwięcej czasu zajmie baza i domyślne porcje, nie kod. |
| Ryzyko techniczne (5 = niskie) | ★★★★☆ | Największe ryzyko: parser polskiego tekstu na długim ogonie. |
| Konkurencja (5 = słaba) | ★★☆☆☆ | Fitatu w PL, dziesiątki trackerów z LLM na świecie. |
| Wyróżnik | ★★★☆☆ | Przejrzystość, konfigurowalność, prywatność, brak abonamentu. Mocny dla niszy, słaby jako hasło masowe. |
| Sens jako projekt dla siebie | ★★★★★ | Szybko daje realną wartość. |

**Werdykt:** warto zrobić jako **projekt dla siebie albo niszowy produkt** (przejrzysty, prywatny, bez abonamentu, dla osób zmęczonych MFP i Fitatu). Kluczowe: zapamiętywanie własnych definicji i deterministyczny parser, z LLM ewentualnie tylko do rozumienia tekstu. Szansa na wybicie się na szerokim rynku jest niska do średniej.

Prompt startowy: [`prompty/04-tracker-jedzenia.md`](prompty/04-tracker-jedzenia.md).

## Źródła

- [Fitatu – wyszukiwanie głosowe AI](https://www.fitatu.com/blog/?p=15682)
- [Fitatu – AI w aplikacji (Spider's Web)](https://spidersweb.pl/2025/03/fitatu-aplikacja-liczenie-kalorii-sztuczna-inteligencja-smartfon.html)
- [Fitatu – rozpoznawanie zdjęć (Tabletowo)](https://www.tabletowo.pl/?p=960186)
- [Natural Macro: Food Journal](https://apps.apple.com/us/app/-/id6758968731)
- [CalNotes: AI Food Diary](https://apps.apple.com/us/app/id6754843029)
- [BitePad](https://www.producthunt.com/p/bitepad/bitepad-2)
- [Healthshape](https://apps.apple.com/us/app/-/id6469450079)
- [Munchlog](https://www.mybesh.com/tool/munchlog)
- [Parsely](https://parsely-web-delta.vercel.app/)
- [CrumbStream](https://crumbstream.pages.dev/)
- [MIT – logowanie jedzenia mową (2016)](https://phys.org/news/2016-03-spoken-language-app-meal-easier-aid.pdf)
- [Trackery ocenione po recenzjach 1-gwiazdkowych (2026)](https://unstar.app/blog/calorie-tracking-apps-ranked-1-star-reviews-2026)
- [Alternatywy dla MyFitnessPal](https://www.trygaya.com/alternatives/myfitnesspal-alternatives)
- [Best calorie counting apps 2026](https://www.welling.ai/articles/best-calorie-counting-app-program)
- [Aplikacje do liczenia kalorii 2026 (Komputronik)](https://nano.komputronik.pl/n/aplikacje-do-liczenia-kalorii-najlepsze-kalkulatory-kalorii-na-smartfon/)
