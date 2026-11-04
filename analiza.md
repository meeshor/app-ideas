# Gry ruchowe: telefon + zegarek — analiza pomysłów

Data: 2026-11-04

## Założenia wspólne dla wszystkich pomysłów

Zanim ocenię pomysły po kolei, kilka faktów, które decydują o tym, co ma sens:

1. **Zegarek to czujnik, a nie ekran.** Daje akcelerometr, żyroskop, orientację (Core Motion na watchOS, ~100 Hz; nowsze modele mają też tryb wysokiej częstotliwości), tętno, Digital Crown i haptykę. Akcję pokazuje telefon (albo telewizor przez AirPlay).
2. **Zegarek nie zna swojej pozycji w przestrzeni, zna tylko orientację i przyspieszenia.** Liczenie przemieszczenia przez całkowanie przyspieszeń dryfuje już po ułamku sekundy. Dlatego dobrze działają **gesty krótkie i wyraźne** (rzut, zamach, szarpnięcie, trzymanie w bezruchu). Słabo działa **ciągłe odwzorowanie 1:1** (miecz, który „podąża” za ręką).
3. **Opóźnienie zegarek → telefon** (WatchConnectivity / Bluetooth) to zwykle kilkadziesiąt do kilkuset ms i bywa niestabilne. Gry, w których liczy się **wynik po wypuszczeniu** (rzut, strzał), na tym nie cierpią. Gry, w których liczy się **trafienie w moment** (odbicie piłki w baseballu), cierpią bardzo.
4. **Rynek:** zegarek jako wymóg zawęża rynek do posiadaczy Apple Watch / Wear OS. Watch + iPhone to jeden spójny ekosystem. Wear OS jest rozdrobniony, a urządzeń Apple i Google nie da się łączyć ze sobą. Rekomendacja: **iOS + watchOS najpierw**, a w każdej grze **tryb bez zegarka** (sterowanie dotykiem lub ruchem samego telefonu), żeby nie odcinać 70–80% graczy.
5. **Bezpieczeństwo:** telefon nie wylatuje z ręki, bo leży albo jest trzymany statycznie. Duże zamachy (golf, dysk, miecz) w mieszkaniu i na ulicy to realne ryzyko.
6. **Konkurencja w niszy „zegarek jako kontroler”** jest mała i amatorska. Istnieją m.in. [DartCast](https://apps.apple.com/us/app/dartcast/id6758662310) (rzutki z Watcha na iPhone), [Air Bowling](https://apps.apple.com/fi/app/air-bowling/id6476380280), historyczny [Bowling Central](https://techcrunch.com/?p=1175140) (2015) oraz narzędzia treningowe ([ThrowKit](https://www.producthunt.com/products/throwkit), [Dartalyzer](https://apps.apple.com/de/app/dartalyzer/id1481477822?l=en-GB), [ArrowSense](https://apps.apple.com/gb/app/arrowsense/id1490650258) dla łuczników). **Nie ma dopracowanej, „premium” gry tego typu.** To szansa, ale też sygnał, że nisza jest mała i trzeba ją poszerzyć trybem bez zegarka.

Skala ocen: 1–5, gdzie 5 = najlepiej. Przy ryzyku i koszcie 5 oznacza ryzyko lub koszt najniższy.

---

## 1. Rzut karny w piłce ręcznej

- **Pasuje do zegarka:** ★★★★☆. Rzut z nadgarstka to wyraźny gest. Siła wynika ze szczytowego przyspieszenia, kierunek z orientacji ręki i rotacji nadgarstka (podkręcenie, „wkrętka”). Ciekawy twist: **zwód**, czyli rozpoczęty i zatrzymany zamach, który AI bramkarza „łapie”.
- **Zabawa / regrywalność:** ★★★☆☆. Zabawne w kilku seriach i w multiplayerze (jedna osoba rzuca, druga broni, wybierając róg na telefonie), ale jako samodzielna gra płytkie.
- **Konkurencja:** brak gier ruchowych z piłką ręczną. Są gry piłkarskie z rzutami karnymi (dotykowe, np. Penalty Shooters). Nisza w niszy: piłka ręczna jest popularna w PL, DE, Skandynawii i FR, ale globalnie mała.
- **Ryzyko techniczne:** ★★★★☆ (niskie).
- **Werdykt:** **dobry mini-tryb, słaba samodzielna aplikacja.** Wchodzi do pakietu „Wrist Arena” (pomysł #3 z finałowej trójki).

## 2. Baseball

- **Pasuje do zegarka:** ★★★☆☆. Detekcja zamachu jest łatwa, ale **gra polega na trafieniu w moment**, a opóźnienie Bluetooth jest zmienne. Da się to łagodzić stemplem czasu z zegarka i synchronizacją zegarów, tylko że każda wpadka czuje się jak „gra oszukuje”. Rzucanie (pitching) działa lepiej niż odbijanie.
- **Zabawa:** ★★★★☆. Home Run Derby to sprawdzona pętla.
- **Konkurencja:** silna w wersji dotykowej (MLB Home Run Derby, Baseball 9, licencjonowane tytuły). Gier ruchowych z Watcha praktycznie brak.
- **Rynek:** głównie USA, Japonia, Korea. W PL marginalny.
- **Ryzyko techniczne:** ★★☆☆☆ (wysokie: latencja).
- **Werdykt:** **odłożyć**, ewentualnie jako późniejszy mini-tryb „pitching” w pakiecie.

## 3. Rzut dyskiem / lekkoatletyka

- **Pasuje do zegarka:** ★★★☆☆. Rzut dyskiem to obrót całego ciała. Zegarek go wykryje (żyroskop), ale w domu to proszenie się o zbitą lampę. Lepsze warianty to pchnięcie kulą, rzut oszczepem i młot (kręcenie ręką w miejscu).
- **Zabawa:** ★★★☆☆. Klasyczna „olimpiada” (jak dawne gry Summer Games) daje rywalizację i rekordy, ale każda konkurencja z osobna jest prosta.
- **Konkurencja:** gry olimpijskie na mobile są dotykowe. Nisza ruchowa jest pusta.
- **Ryzyko techniczne:** ★★★★☆.
- **Werdykt:** **mini-tryby do pakietu** (oszczep, kula). Samodzielnie nie warto.

## 4. Rzutki (darts)

- **Pasuje do zegarka:** ★★★★★. Krótki rzut z nadgarstka, ręka niemal nieruchoma przed rzutem, bez dużego zamachu. **Najlepsze dopasowanie fizyczne ze wszystkich pomysłów**, idealne do mieszkania i pubu.
- **Zabawa:** ★★★★☆. 501, Cricket, Around the Clock, multiplayer „pass & play” (przekazujemy sobie zegarek albo każdy ma swój).
- **Konkurencja:** **jest bezpośredni konkurent**, [DartCast](https://apps.apple.com/us/app/dartcast/id6758662310) (0,99 $, prosty). Mnóstwo dotykowych gier w rzutki (Darts of Fury, Darts Club). Bariera wejścia jest niska, więc łatwo o naśladowców.
- **Ryzyko techniczne:** ★★★★★ (najniższe).
- **Werdykt:** **najlepszy „pierwszy moduł” na start**, ale sam w sobie łatwy do skopiowania. Dlatego stanowi rdzeń pakietu „Wrist Arena”.

## 5. Łucznictwo (zegarkiem naciągamy cięciwę)

- **Pasuje do zegarka:** ★★★★★. Łucznictwo to fazy, które zegarek świetnie rozpoznaje: **uniesienie → naciąg → kotwica → trzymanie w bezruchu → zwolnienie**. Kluczowe jest to, że **jakość strzału zależy od stabilności ręki**, a to zegarek mierzy znakomicie (drgania z żyroskopu). Bonus, którego nikt nie ma: **tętno** z zegarka wpływa na kołysanie celownika („uspokój oddech”). Naturalny podział ról: **telefon w ręce łuku = łuk/celownik** (żyroskop telefonu celuje), **zegarek na ręce naciągającej = cięciwa**.
- **Zabawa:** ★★★★☆. Satysfakcjonujące, „medytacyjne”, dobre do krótkich sesji i codziennych wyzwań. Głębia przez wiatr, dystanse, ruchome cele, typy łuków.
- **Konkurencja:** dużo dotykowych gier łuczniczych (Archery King, Archery Go, Core Archery, Bowmasters), [ArrowSense](https://apps.apple.com/gb/app/arrowsense/id1490650258) to tracker treningowy dla prawdziwych łuczników, a nie gra. **Gry łuczniczej sterowanej Watchem nie znalazłem.** Wolna nisza z jasnym wyróżnikiem.
- **Ryzyko techniczne:** ★★★★☆. Rozpoznanie naciągu i zwolnienia wymaga strojenia, a lewo-/praworęczność plus to, na której ręce jest zegarek, trzeba obsłużyć konfiguracją.
- **Werdykt:** **TOP. Najlepszy pomysł flagowy.**

## 6. Golf (zegarkiem uderzamy)

- **Pasuje do zegarka:** ★★★★☆. Detekcję zamachu golfowego z zegarka robią już aplikacje do prawdziwego golfa, więc temat jest dobrze zbadany. Pełny zamach w domu jest jednak ryzykowny. **Putting / mini-golf** jest bezpieczny i precyzyjny.
- **Zabawa:** ★★★★☆.
- **Konkurencja:** bardzo silna w wersji dotykowej (Golf Clash, WGT, Golf Rival), dojrzałe trackery do prawdziwego golfa (Garmin, Hole19, Arccos). Pełna gra golfowa wymaga dużo contentu (pola, fizyka piłki, trawa).
- **Ryzyko techniczne:** ★★★☆☆. Koszt contentu jest wysoki.
- **Werdykt:** **mocny kandydat nr 4.** Jako samodzielna gra za drogi. Jako **mini-golf (putting)** w pakiecie „Wrist Arena” ma sens w drugiej fazie.

## 7. AR w mieście (przeciwnicy na ulicy / łuk, proca, miecz)

- **Pasuje do zegarka:** ★★☆☆☆. **Walka na miecze nie zadziała dobrze**: zegarek nie zna pozycji ręki, więc wyjdzie „machanie” rozpoznawane jako kilka gestów (cięcie poziome, pionowe, pchnięcie, blok), a nie szermierka. Strzelanie z łuku lub procy w AR działa, ale to po prostu pomysł #5 lub #8 z kamerą.
- **Zabawa:** ★★★★☆ w teorii.
- **Konkurencja:** **miażdżąca**. Pokémon GO, Monster Hunter Now i Pikmin Bloom od Niantic/Scopely, Orna i inne GPS RPG. Wejście w gry lokalizacyjne wymaga ogromnego contentu, serwerów, mapy POI i moderacji.
- **Bezpieczeństwo:** machanie rękami z telefonem przy ruchliwej ulicy to realne ryzyko (oraz kwestie prawne i wizerunkowe). AR + GPS + kamera mocno drenują baterię.
- **Ryzyko techniczne / koszt:** ★☆☆☆☆.
- **Werdykt:** **odrzucić wersję miejską.** Wartościowa część tego pomysłu, czyli **AR na stole / w pokoju**, trafia jako tryb do gry z procą (#8).

## 8. „Angry Birds 3D”: naciągamy zegarkiem i patrzymy, co się niszczy

- **Pasuje do zegarka:** ★★★★☆. Naciąg procy to ten sam typ gestu co łuk (naciąg → trzymanie → puszczenie), z tą różnicą, że **liczy się siła i kąt, a nie precyzja**. Telefon trzymany w drugiej ręce może być „widełkami” i celownikiem, albo leży na stole w trybie AR.
- **Zabawa:** ★★★★★. Destrukcja fizyczna daje największy „wow” i najlepiej wygląda na nagraniach (TikTok/Reels to darmowy marketing). Regrywalność dają poziomy, gwiazdki i powtórki w zwolnionym tempie.
- **Konkurencja:** Angry Birds AR: Isle of Pigs (Rovio + Resolution Games, 2019, ARKit) [pokazało, że to działa](https://www.rovio.com/articles/rovio-and-resolution-games-give-the-green-light-to-angry-birds-ar-isle-of-pigs-released-today-in-the-app-store/), ale [nie jest już rozwijane](https://apps.qoo-app.com/de/app/10304?f=note). Gatunek „physics destruction” jest zatłoczony w wersji dotykowej (klony Angry Birds, Smash Hit, gry z katapultami), ale **3D + sterowanie Watchem + AR na stole to niezajęte połączenie**. Trzeba mieć **własny świat i bohaterów**, a nie kopiować ptaki i świnie.
- **Ryzyko techniczne:** ★★★☆☆. Fizyka destrukcji na telefonie (wydajność, stabilność stosów brył) i projektowanie poziomów to najwięcej pracy ze wszystkich pomysłów.
- **Werdykt:** **TOP. Największy potencjał viralowy.**

---

## Tabela zbiorcza

| # | Pomysł | Dopasowanie do zegarka | Zabawa | Luka rynkowa | Ryzyko tech. (5 = niskie) | Koszt (5 = niski) | Suma |
|---|---|:-:|:-:|:-:|:-:|:-:|:-:|
| 5 | Łucznictwo | 5 | 4 | 5 | 4 | 4 | **22** |
| 8 | Proca 3D / destrukcja | 4 | 5 | 4 | 3 | 2 | **18** |
| 4 | Rzutki | 5 | 4 | 2 | 5 | 5 | **21** → rdzeń pakietu |
| 6 | Golf | 4 | 4 | 2 | 3 | 2 | 15 |
| 1 | Karny w ręcznej | 4 | 3 | 3 | 4 | 4 | 18 → do pakietu |
| 3 | Dysk / lekkoatletyka | 3 | 3 | 3 | 4 | 4 | 17 → do pakietu |
| 2 | Baseball | 3 | 4 | 3 | 2 | 3 | 15 |
| 7 | AR w mieście | 2 | 4 | 1 | 1 | 1 | 9 |

## Wybrana trójka

1. **Łucznictwo z Watchem** (roboczo „Cięciwa” / *Drawstring*): flagowiec, najczystsze dopasowanie do czujników, wolna nisza, unikalny wyróżnik w postaci stabilności ręki i tętna.
2. **Proca 3D z destrukcją + tryb AR na stole** (roboczo *Slingworks*): największy efekt „wow” i potencjał viralowy. Wchłania sensowną część pomysłu AR.
3. **Pakiet sportów z nadgarstka** (roboczo *Wrist Arena*): rzutki jako rdzeń MVP, do tego rzut karny w ręcznej, a później oszczep/kula, mini-golf i pitching. Pojedyncze moduły są łatwe do skopiowania (DartCast już istnieje), ale **pakiet imprezowy z multiplayerem i obrazem na TV** jest trudniejszy do podrobienia i lepiej się sprzedaje.

### Rekomendacja strategiczna

Wszystkie trzy gry potrzebują tego samego fundamentu: **aplikacji na zegarek, która rozpoznaje gesty (naciąg, trzymanie, zwolnienie, rzut, zamach) lokalnie na zegarku i wysyła na telefon zwięzłe zdarzenia z parametrami**, plus nagrywania i odtwarzania ruchu do testów (symulator nie ma czujników). Warto to zbudować **raz jako wspólny pakiet** (roboczo `WristKit`) i potem użyć w trzech grach.

Kolejność:
1. Rzutki w *Wrist Arena*: najszybszy MVP, który przy okazji waliduje `WristKit` na prostym geście.
2. *Cięciwa* (łucznictwo): flagowiec.
3. *Slingworks*: największy projekt, startuje z gotowym `WristKit` i doświadczeniem z naciągiem z łuku.

Gotowe prompty startowe są w katalogu [`prompty/`](prompty/).
