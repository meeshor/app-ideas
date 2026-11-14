# Wrist Arena

Imprezowy pakiet sportów z nadgarstka: gest wykonujesz ręką z Apple Watch, a obraz jest na iPhonie, iPadzie lub TV (AirPlay).
Pierwszy moduł: **rzutki**.

## Struktura

```
wrist-arena/
  project.yml          opis projektu dla XcodeGen (.xcodeproj generujemy, nie commitujemy)
  Config/              Base.xcconfig + Twój Signing.xcconfig (poza repo)
  ArenaCore/           Swift Package: reguły, punktacja, tury (czysty Swift, testy)
  App/iOS/             aplikacja na iPhone/iPad (SwiftUI, później SpriteKit)
  App/Watch/           aplikacja na zegarek (SwiftUI, rozpoznawanie gestów)
../WristKit/           wspólny pakiet ruchu i gestów
```

## Wymagania

- Mac z Xcode 16 lub nowszym (iOS 18 / watchOS 11 SDK)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- iPhone z iOS 18+ sparowany z Apple Watch z watchOS 11+, oba w trybie deweloperskim
  (iPhone: Ustawienia → Prywatność i ochrona → Tryb deweloperski; Watch: Ustawienia → Prywatność i ochrona → Tryb deweloperski)

## Uruchomienie na sparowanym iPhonie i Watchu

1. Ustaw podpis (raz):
   ```sh
   cd wrist-arena
   cp Config/Signing.xcconfig.example Config/Signing.xcconfig
   # wpisz swój DEVELOPMENT_TEAM (Xcode → Settings → Accounts → Team ID)
   ```
2. Wygeneruj projekt (po każdej zmianie `project.yml` albo dodaniu plików):
   ```sh
   xcodegen generate
   open WristArena.xcodeproj
   ```
3. iPhone: schemat **WristArena**, urządzenie = Twój iPhone → Run. Aplikacja na zegarek jest osadzona
   w aplikacji iOS i instaluje się na sparowanym Watchu (Watch na iPhonie → Dostępne aplikacje,
   jeśli nie pojawi się sama).
4. Zegarek bezpośrednio: schemat **WristArenaWatch**, urządzenie = Twój Watch → Run (szybsze iteracje
   i logi z zegarka). Pierwsze połączenie z zegarkiem w Xcode potrafi trwać kilka minut.

Przy pierwszym nagrywaniu zegarek poprosi o zgodę na sesję treningu (HealthKit). Sesja pozwala
czytać ruch przy opuszczonym nadgarstku, a trening nie jest zapisywany w Zdrowiu.

Bundle ID: `com.meeshor.wristarena` i `com.meeshor.wristarena.watchkitapp`. Inny prefiks ustawisz
przez `BUNDLE_ID_PREFIX` w `Signing.xcconfig`.

## Testy

```sh
cd ArenaCore && swift test        # logika gry
cd ../../WristKit && swift test   # silnik gestów
```

CI (GitHub Actions, `macos-latest`) uruchamia oba zestawy testów, buduje obie aplikacje bez podpisu
i puszcza SwiftLint (na Linuksie). Workflowy mają filtry `paths`.

## Kamienie milowe

- [x] **M0:** szkielet, pakiety, CI, SwiftLint
- [x] **M1:** nagrywanie i podgląd ruchu, wykresy, pomiar opóźnienia, eksport nagrań (ekran „Czujniki (debug)”, [`docs/latency.md`](docs/latency.md), [`docs/recording-protocol.md`](docs/recording-protocol.md))
- [x] **M2:** `FlickThrowRecognizer`, tarcza, 501, pass & play, kalibracja (szczegóły niżej; progi do strojenia na zegarku: [`docs/tuning.md`](docs/tuning.md))
- [ ] **M3:** Cricket, Around the Clock, ekran TV, statystyki, tryb dotykowy
- [ ] M4: ręczna (po akceptacji)
- [ ] M5: menu modułów, onboarding, Game Center

## M2: co jest i jak to sprawdzić

**Gotowe i przetestowane bez urządzenia** (`swift test`, działa też na Linuksie):

- `FlickThrowRecognizer` (WristKit): rzut z nadgarstka, odporność na machanie, drapanie, opuszczanie ręki,
  obrót przedramienia i drżenie. 20 syntetycznych nagrań wg [`docs/recording-protocol.md`](docs/recording-protocol.md).
  Prawdziwe nagrania z `WristKit/Tests/WristKitTests/Fixtures/real/` są testowane automatycznie według etykiety w nazwie pliku.
- `SyntheticMotion`: generator ruchu ręki (testy i przycisk **Symuluj rzut** w aplikacji, bo symulator nie ma czujników).
- `CalibrationSession`: 3 rzuty w środek z odrzuceniem rozrzuconej serii.
- ArenaCore: `DartThrowModel` (kierunek, siła, jerk i spin → punkt na tarczy z rozrzutem), `X01Rules`
  (301/501/701, double-out, double-in, bust, podpowiedź zamknięcia), `DartsMatch` (pass & play 1–4 graczy, cofanie, zapis stanu).

**Aplikacje** (napisane bez Xcode, kompilację sprawdza CI na macOS):

- Zegarek: sesja gry (recognizer na żywo, haptyka „gotowy” i „rzucone”, ekran gracza), nadal nagrywanie i podgląd z M1.
- iPhone: **Rzutki** → gracze (nadgarstek, poziom, kalibracja), wariant, wejście (zegarek/dotyk) → mecz:
  tablica wyników ze średnią, tarcza z trafieniami, ekran „Podaj zegarek”, cofanie, podpowiedź zamknięcia, ekran zwycięzcy.
- Bez zegarka: tryb **Dotyk** (stuknięcie w tarczę = celowanie z rozrzutem) i **Symuluj rzut** (syntetyczny ruch przez ten sam recognizer).

**Do sprawdzenia na zegarku** (kolejno):

1. Oś przedramienia: tabela w [`docs/tuning.md`](docs/tuning.md#1-najpierw-oś-przedramienia-wristorientation). Jeśli jest odwrócona, kierunki będą lustrzane albo odwrócone.
2. Zegarek (ekran główny → **Rzutki (test)**): przy nieruchomej ręce krótkie kliknięcie i zielony celownik („Gotowy”), po rzucie potwierdzenie haptyczne. Licznik rzutów rośnie o 1 na rzut, nie rośnie przy machaniu ani drapaniu się.
3. Nagraj zestaw z protokołu i wrzuć do `Fixtures/real/`. `swift test` pokaże, które przypadki się nie zgadzają.
4. iPhone → Rzutki → **Kalibruj** każdego gracza → mecz 501 dla 2 graczy z przekazywaniem zegarka. Sprawdź:
   - czy rzut „w lewo/prawo/górę/dół” przesuwa rzutkę w tę samą stronę;
   - czy opóźnienie od rzutu do kropki na tarczy jest akceptowalne (zdarzenie wychodzi ok. 0,2 s po rzucie, plus transport);
   - czy lewa ręka (zegarek przełożony na drugi nadgarstek, koronka od strony dłoni) działa tak samo.
5. Zmierz opóźnienie (ekran Czujniki) i uzupełnij [`docs/latency.md`](docs/latency.md).
