# Strojenie gestu i rzutek

Wszystkie progi są w dwóch plikach, oznaczone **DO STROJENIA**:

- `WristKit/Sources/WristKit/Gestures/GestureTuning.swift`: `FlickTuning` (rozpoznawanie rzutu na zegarku),
- `wrist-arena/ArenaCore/Sources/ArenaCore/Darts/DartThrowModel.swift`: `DartsTuning` (rzut → punkt na tarczy).

Wartości startowe dobrane są na **syntetycznym** ruchu (`SyntheticMotion`). Przechodzą 20 przypadków
testowych i 2000 przebiegów z losowym szumem, kierunkiem i przekręceniem zegarka. Prawdziwa ręka
na pewno będzie inna. Kolejność strojenia jest poniżej.

## 1. Najpierw: oś przedramienia (`WristOrientation`)

Wszystkie kierunki zależą od tego, która oś zegarka wskazuje dłoń. Założenie: lewy nadgarstek
z koronką od strony dłoni (domyślnie) to +x, prawy nadgarstek z koronką od strony dłoni to −x.
Zakładamy też, że Core Motion **nie** przelicza osi po zmianie orientacji w ustawieniach.

Sprawdzenie (ekran **Czujniki**, podgląd na żywo, wykres grawitacji albo nagranie):

| Poza ręki | Grawitacja w osi dłoni (`gravity · handAxis`) |
|---|---|
| ręka wyciągnięta poziomo do przodu | ≈ 0 |
| dłoń w górę (przedramię pionowo) | ≈ −1 |
| dłoń w dół (ręka zwisa) | ≈ +1 |

Jeśli znak wychodzi odwrotny, popraw `WristOrientation.handAxis` (albo `DeviceInfo.orientation`).
Dopiero wtedy warto włączyć `minReadyElevation` (np. −0,5 rad). Odrzuca on ruchy z ręką opuszczoną.

## 2. Rozpoznawanie rzutu (`FlickTuning`)

Maszyna stanów jest opisana w `FlickThrowRecognizer.swift`. Na co patrzeć w nagraniach z protokołu:

| Objaw | Próg |
|---|---|
| zegarek nie łapie „gotowy” (brak kliknięcia haptycznego) | `stillness.maxRotationRate`, `stillness.maxUserAcceleration` w górę albo `minDuration` w dół |
| `flick_center` nie daje rzutu | `minPeakRotationRate`, `minPeakAcceleration` w dół; `maxActiveDuration` w górę przy długim zamachu |
| zamach w tył kasuje rzut | `pauseTolerance` w górę |
| `noise_wave` / `noise_scratch` daje rzut | `reboundRatio` w dół albo `confirmWindow` w górę |
| `noise_lower` daje rzut | `startRotationRate` / `minPeakRotationRate` w górę, `minReadyElevation` |
| `flick_twist` odrzucony | `maxSpinShare` w górę |
| zdarzenie przychodzi za późno | `confirmWindow` w dół (kosztem większej liczby fałszywych rzutów) |
| `jerk` zawsze ≫ 1 albo ≈ 0 | `jerkForUnit` = typowy szczyt jerku spokojnego rzutu (g/s) |

Pętla strojenia:

1. Nagraj zestaw z `docs/recording-protocol.md` i wrzuć pliki do `WristKit/Tests/WristKitTests/Fixtures/real/`.
2. `cd WristKit && swift test`. Test `realRecordingsMatchExpectations` wypisze każde niezgodne nagranie
   z powodem (np. `noise_wave_01: oczekiwano 0 rzutów, jest 1`).
3. Zmień próg, powtórz. Syntetyczny zestaw musi dalej przechodzić. Jeśli się rozjedzie,
   popraw generator (`SyntheticMotion`) tak, żeby był bliżej prawdziwych danych.

Progi można też zmieniać bez przebudowy: telefon wysyła `ControlCommand.updateTuning`, a zegarek
podmienia `recognizer.tuning`. Ekranu z suwakami jeszcze nie ma (kandydat do M3).

## 3. Rzut → tarcza (`DartsTuning`)

| Parametr | Co robi | Jak stroić |
|---|---|---|
| `aimGain` | ile mm na tarczy daje 1 rad odchylenia (× 2370 mm) | gdy łatwo trafić w T20 i bull: w górę; gdy rzutki lecą „gdzie chcą”: w dół |
| `referenceSpeed` | prędkość bez opadania | średni `speed` spokojnego rzutu gracza (patrz debug) |
| `dropAtEightyPercent` | opadanie słabszego rzutu | im większe, tym ważniejsza siła rzutu |
| `spread[difficulty]` | bazowy rozrzut (σ, mm) | normal ≈ 14 mm: dobry rzut zostaje w sektorze, rzadko w T20 |
| `jerkSpreadGain`, `spinSpreadGain` | kara za szarpnięcie / skręt | gdy kara jest odczuwalna jako „losowa”: w dół |

Kalibracja gracza (3 rzuty w środek) przesuwa średni kierunek, więc `aimGain` dotyczy tylko odchyleń
od własnego, typowego rzutu.
