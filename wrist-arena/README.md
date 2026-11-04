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
- [ ] **M1:** nagrywanie i podgląd ruchu, wykresy, pomiar opóźnienia, eksport nagrań
- [ ] **M2:** `FlickThrowRecognizer`, tarcza, 501, pass & play, kalibracja
- [ ] **M3:** Cricket, Around the Clock, ekran TV, statystyki, tryb dotykowy
- [ ] M4: ręczna (po akceptacji)
- [ ] M5: menu modułów, onboarding, Game Center
