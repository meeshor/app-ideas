# Prompt startowy: „Cięciwa” — łucznictwo sterowane Apple Watch

> Skopiuj wszystko poniżej linii do nowej sesji Claude Code w pustym repozytorium.

---

Budujemy grę mobilną **„Cięciwa”** (nazwa robocza, ang. *Drawstring*): realistyczne, ale przystępne łucznictwo, w którym **iPhone trzymany w ręce łuku jest łukiem i celownikiem**, a **Apple Watch na ręce naciągającej rozpoznaje naciąg i zwolnienie cięciwy**. Gra jest oryginalna: własny styl graficzny, własne lokacje, bez nawiązań do istniejących marek.

## Cel produktu

- Krótkie sesje (2–5 min), satysfakcja z precyzji, codzienne wyzwanie.
- Wyróżnik: **jakość strzału zależy od tego, jak stabilnie trzymasz rękę w fazie kotwicy** (mierzone żyroskopem zegarka), a **tętno z zegarka zwiększa kołysanie celownika**. Mechanika „uspokój się i oddychaj”.
- Musi działać też **bez zegarka** (tryb dotykowy: przeciągnięcie palcem = naciąg, żyroskop telefonu = celowanie). To nie jest dodatek, tylko warunek wielkości rynku.

## Platforma i stos

- iOS 18+ / watchOS 11+, Swift 6, SwiftUI do UI.
- Grafika 3D: **RealityKit** (SceneKit jest przestarzały, nie używaj go). Jeśli przy prototypie RealityKit okaże się zbyt ograniczający, zatrzymaj się i przedstaw mi porównanie z Unity, zanim zmienisz kierunek.
- Komunikacja zegarek ↔ telefon: WatchConnectivity (`WCSession.sendMessage` / `sendMessageData`). Zmierz realne opóźnienie i opisz je w `docs/latency.md`.
- Zegarek: Core Motion (`CMMotionManager` deviceMotion ~100 Hz), HealthKit (tętno), `HKWorkoutSession`, żeby aplikacja na zegarku działała z opuszczonym nadgarstkiem i wygaszonym ekranem. Haptyka zegarka przy naciągu i puszczeniu.
- Bez backendu w MVP. Game Center na rankingi i osiągnięcia.

## Architektura (wymagana)

Wydziel **lokalny Swift Package `WristKit`**, którego później użyją inne gry. Ma w nim być:

1. `MotionSample`: znacznik czasu, attitude (kwaternion), rotationRate, userAcceleration, gravity.
2. `GestureRecognizer`: protokół plus implementacja `DrawReleaseRecognizer`, maszyna stanów:
   `idle → raised → drawing → anchored → released` (oraz `cancelled`, gdy ręka opadnie bez strzału).
   - `raised`: wektor grawitacji wskazuje uniesione przedramię (próg konfigurowalny).
   - `drawing`: ciągłe przyspieszenie liniowe wzdłuż osi przedramienia w stronę ciała. **Siła naciągu** = znormalizowana miara (czas trwania × średnie przyspieszenie, z limitem), a nie całkowanie pozycji, bo całkowanie dryfuje.
   - `anchored`: niska wariancja rotationRate przez ≥ 300 ms. W tej fazie liczymy **stabilność** (RMS żyroskopu w oknie 0,5 s).
   - `released`: gwałtowny skok przyspieszenia lub rotacji (ręka odskakuje do tyłu przy puszczeniu cięciwy). Alternatywa: tap na ekranie zegarka albo obrót Digital Crown (ustawienia dostępności).
3. **Rozpoznawanie gestów działa NA ZEGARKU.** Na telefon idą tylko zdarzenia (`drawStarted(strength)`, `anchored(stability)`, `released(strength, stability, heartRate, watchTimestamp)`) plus podgląd stabilności co ~50 ms, żeby celownik „pływał” na żywo.
4. `MotionRecorder` / `MotionReplayer`: nagrywanie surowych próbek z zegarka do pliku (JSON lub binarnie) i ich odtwarzanie w symulatorze oraz w testach jednostkowych. **Symulator nie ma czujników**, więc to jedyny sposób, żeby testować rozpoznawanie bez urządzenia. Dodaj kilka syntetycznych nagrań (wygenerowanych skryptem) do testów.
5. Konfiguracja ręki: na której ręce jest zegarek (lewa/prawa) i czy jest to ręka naciągająca, czy ręka łuku. Jeśli zegarek jest na ręce łuku, przełącz role: zegarek celuje, a naciąg robimy gestem palca na telefonie trzymanym w drugiej ręce.

Aplikacja na telefon: `GameCore` (fizyka strzały, wiatr, punktacja, czysty Swift, testowalny), `GameScene` (RealityKit), `Input` (adaptery: Watch / Touch / Replay).

## Mechanika gry

- Celowanie: orientacja telefonu (attitude) z kalibracją „patrz prosto i dotknij”. Wygładzanie, lekkie przyspieszenie przy dużych ruchach.
- Kołysanie celownika = f(stabilność z zegarka, tętno powyżej spoczynkowego, czas trzymania). Za długie trzymanie zwiększa drżenie (zmęczenie). Okno „idealnego” strzału 2–4 s.
- Strzała: balistyka z grawitacją i wiatrem, prędkość początkowa proporcjonalna do siły naciągu. Kamera podąża za strzałą przy trafieniach blisko środka (slow-mo).
- Tryby MVP:
  1. **Tarcza**: 18 m i 30 m, 10 pierścieni, serie po 3 strzały, rekord osobisty.
  2. **Wyzwanie dnia**: stały seed (data), te same warunki wiatru dla wszystkich, ranking Game Center.
- Po MVP: ruchome cele (balony, wahadła), dystanse 50/70 m, różne łuki (refleksyjny, bloczkowy, długi) ze zmienną charakterystyką, tryb AR (tarcza postawiona w pokoju przez ARKit), multiplayer na zmianę.
- Feedback po strzale: wykres stabilności z fazy kotwicy, tętno, siła naciągu i jedna wskazówka („puściłeś za wcześnie”, „ręka drżała”).

## Kamienie milowe

1. **M0 — Szkielet:** projekt Xcode (iOS app + watchOS app + `WristKit`), CI z `xcodebuild test` dla `WristKit` i `GameCore`, SwiftLint.
2. **M1 — Czujniki:** aplikacja na zegarek nagrywa i wysyła próbki, ekran debug na telefonie pokazuje wykresy na żywo i fazy maszyny stanów. Pomiar opóźnienia.
3. **M2 — Rozpoznawanie:** `DrawReleaseRecognizer` z testami na nagraniach (min. 10 przypadków: poprawny strzał, słaby naciąg, anulowanie, drżenie, fałszywe szarpnięcie bez naciągu).
4. **M3 — Grywalny prototyp:** jedna tarcza, celowanie telefonem, strzał z zegarka, punktacja. Tryb dotykowy działa bez zegarka.
5. **M4 — MVP:** oba tryby MVP, wiatr, feedback po strzale, onboarding (kalibracja i wybór ręki), Game Center, ustawienia dostępności.

Po każdym kamieniu zatrzymaj się, opisz, co działa, czego nie da się sprawdzić bez fizycznego urządzenia i co mam przetestować na swoim zegarku.

## Zasady pracy

- Zacznij od krótkiego planu (struktura katalogów, kluczowe typy, ryzyka) i poczekaj na moją akceptację.
- Logika gry i rozpoznawanie gestów muszą być testowalne bez urządzenia. Progi gestów trzymaj w jednym pliku konfiguracyjnym, żebym mógł je stroić.
- Nie zgaduj stałych fizycznych na ślepo: zostaw w kodzie komentarz, skąd jest wartość, albo oznacz ją jako „do strojenia”.
- Pisz krótkie commity z opisem. README z instrukcją uruchomienia na urządzeniu (parowanie, uprawnienia HealthKit i Motion).
