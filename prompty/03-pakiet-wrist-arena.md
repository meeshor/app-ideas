# Prompt startowy: „Wrist Arena” — imprezowy pakiet sportów z nadgarstka

> Skopiuj wszystko poniżej linii do nowej sesji Claude Code w pustym repozytorium.

---

Budujemy **„Wrist Arena”** (nazwa robocza): pakiet krótkich gier sportowych sterowanych ruchem ręki z Apple Watch, z obrazem na iPhonie, iPadzie lub telewizorze (AirPlay). Idea: „konsola ruchowa, którą masz już na ręce”. Grafika, postacie i nazwy są oryginalne. Nie odtwarzamy żadnej istniejącej gry ani serii.

## Cel produktu

- Gra na imprezę / do pubu / na wieczór z rodziną: **pass & play** (jeden zegarek przekazywany z ręki do ręki) i **kilka zegarków jednocześnie** (każdy gracz ze swoim iPhonem + Watchem w tej samej sieci; to po MVP).
- Każdy moduł to osobny gest. Wszystkie korzystają z jednego silnika gestów.
- Tryb bez zegarka w każdym module (sterowanie dotykiem lub ruchem samego telefonu trzymanego w dłoni, bez rzucania nim). Zapobiegaj przypadkowemu rzuceniu telefonem: w trybie „telefon w ręce” wymagaj trzymania przycisku i ostrzeż w onboardingu.

## Moduły

**MVP (w tej kolejności):**
1. **Rzutki:** gest krótkiego rzutu z nadgarstka. Kierunek z orientacji przedramienia w chwili puszczenia (pitch → wysokość, yaw/roll → bok), siła z prędkości ruchu do przodu. Rozrzut rośnie z „szarpnięciem” (jerk) i rotacją nadgarstka w trakcie rzutu. Gry: 501 (double-out opcjonalnie), Cricket, Around the Clock. Ogólny rozrzut regulowany poziomem trudności, a kalibracja „trzy rzuty w środek” ustala indywidualne przesunięcia.
2. **Rzut karny w piłce ręcznej:** gest rzutu z zamachem. Kierunek i wysokość jak wyżej, rotacja nadgarstka = podkręcenie, a **zwód** (zamach rozpoczęty i zatrzymany przed puszczeniem) wpływa na reakcję bramkarza AI. Tryb 2 graczy: drugi gracz broni, wybierając róg na telefonie (ukrycie wyboru przed rzucającym).

**Po MVP (nie implementuj teraz, ale zaprojektuj tak, żeby się dało dodać):** oszczep i pchnięcie kulą, mini-golf (putting: wahadłowy ruch ręki), pitching w baseballu. Celowo pomijamy gry wymagające trafienia w moment (odbijanie piłki), bo opóźnienie Bluetooth jest zmienne. Jeśli kiedyś do tego dojdziemy, potrzebna będzie synchronizacja zegarów i stemple czasu z zegarka.

## Platforma i stos

- iOS 18+ / iPadOS 18+ / watchOS 11+, Swift 6, SwiftUI.
- Rendering: **SpriteKit** dla rzutek (2.5D wystarczy), **RealityKit** dla ręcznej. SceneKit jest przestarzały, nie używaj go.
- Wyjście na TV: AirPlay / drugi ekran (`UIScene` external display), z UI dopasowanym do dużego ekranu i telefonem jako „panelem kontrolnym”.
- Zegarek: Core Motion ~100 Hz, `HKWorkoutSession` (praca z opuszczonym nadgarstkiem), haptyka przy trafieniach.
- Bez backendu w MVP. Game Center na rankingi.

## Architektura (wymagana)

**Lokalny Swift Package `WristKit`**, wspólny dla wszystkich modułów (i dla moich innych gier):

- `MotionSample`, `MotionStream` (zegarek → telefon), `MotionRecorder` / `MotionReplayer` (nagrania do testów, bo symulator nie ma czujników).
- Protokół `GestureRecognizer` i implementacje: `FlickThrowRecognizer` (rzutki), `OverarmThrowRecognizer` (ręczna, ze zwodem), w przyszłości `SwingRecognizer`, `PendulumRecognizer`.
- **Rozpoznawanie odbywa się na zegarku.** Na telefon idą zdarzenia `ThrowEvent { speed, direction(pitch,yaw), spin, jerk, isFeint, watchTimestamp }`. Dla rzutów opóźnienie przesyłu jest niekrytyczne (animacja startuje po zdarzeniu), ale je zmierz i opisz w `docs/latency.md`.
- `PlayerProfile`: ręka z zegarkiem, kalibracja, poziom trudności. Wsparcie leworęcznych.

Aplikacja: `ArenaCore` (logika modułów, punktacja, tury graczy; czysty Swift, w pełni testowalny), moduły jako osobne targety lub foldery z jednolitym interfejsem `GameModule` (nazwa, wymagany gest, ekran gry, reguły), `Input` (adaptery: Watch / Touch / PhoneMotion / Replay).

## Kamienie milowe

1. **M0 — Szkielet:** Xcode (iOS + watchOS + `WristKit`), CI z testami `WristKit` i `ArenaCore`, SwiftLint.
2. **M1 — Czujniki:** nagrywanie i podgląd ruchu na żywo, ekran debug z wykresami, pomiar opóźnienia, eksport nagrań.
3. **M2 — Rzutki grywalne:** `FlickThrowRecognizer` z testami na nagraniach (min. 10 przypadków), tarcza, 501, pass & play dla 2–4 graczy, kalibracja.
4. **M3 — Rzutki MVP:** Cricket, Around the Clock, ekran TV, statystyki gracza, tryb dotykowy.
5. **M4 — Ręczna:** `OverarmThrowRecognizer` ze zwodem, bramkarz AI, tryb 2 graczy.
6. **M5 — Pakiet:** menu wyboru modułów, onboarding (bezpieczeństwo: pasek zegarka zapięty, wolna przestrzeń wokół), Game Center.

Po każdym kamieniu: co działa, czego nie da się sprawdzić bez urządzenia i co dokładnie mam przetestować na zegarku.

## Zasady pracy

- Najpierw plan (struktura repo, interfejs `GameModule`, kształt `ThrowEvent`, ryzyka) i czekaj na moją akceptację.
- Progi i krzywe gestów w jednym pliku konfiguracyjnym, oznaczone „do strojenia”.
- Logika gry i rozpoznawanie gestów testowalne bez urządzenia, na nagraniach.
- Krótkie, opisowe commity, README z instrukcją uruchomienia na sparowanym iPhonie i Watchu.
