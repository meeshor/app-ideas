# WristKit

Wspólny silnik ruchu i gestów z Apple Watch dla gier Wrist Arena, Cięciwa i Slingworks.
Nie zależy od żadnej z gier.

| Produkt | Zawartość | Platformy |
|---|---|---|
| `WristKit` | `MotionSample`, `MotionRecording` (`.wkrec`), `MotionRecorder`/`MotionReplayer`, `GestureRecognizer`, `FlickThrowRecognizer`, `ThrowGeometry`, `WristOrientation`, `GestureTuning` (progi **do strojenia**), `SyntheticMotion` (generator ruchu), `CalibrationSession`, `SeededRandom`, `ThrowEvent`, `WristMessage`, `ClockSync`, `LatencySummary`, `PlayerProfile`, `RingBuffer`, `SampleBatcher`, `RecordingStore`, `MonotonicClock` | iOS, watchOS, macOS (testy) |
| `WristKitDevice` | `LiveMotionSource` (Core Motion 100 Hz), `WorkoutSessionController` (`HKWorkoutSession`), `WatchLink` (WatchConnectivity: wiadomości, pliki, auto-pong), `Haptics`, `DeviceInfo` | iOS, watchOS |

`WristKit` to czysty Swift (sam Foundation), więc testy idą bez symulatora:

```sh
cd WristKit && swift test
```

Uwaga: `WristKitDevice` jest chroniony warunkiem `#if os(watchOS) || os(iOS)`, a nie
`canImport(CoreMotion)`, bo CoreMotion istnieje na macOS, a `CMMotionManager` tam nie działa.

## Zasady

- Rozpoznawanie gestów odbywa się na zegarku, a na telefon idą zwięzłe zdarzenia (`ThrowEvent`) i opcjonalnie stan „na żywo” (~20 Hz).
- Kąty w zdarzeniach są względne do pozy „ready” i zlustrzone dla lewej ręki.
- Każdy recognizer to deterministyczna maszyna stanów, testowana na nagraniach.

## Testy na nagraniach

`FlickFixtureTests` sprawdza recognizer na 20 syntetycznych nagraniach (etykiety jak w
`wrist-arena/docs/recording-protocol.md`) i na wszystkich plikach `.wkrec` z
`Tests/WristKitTests/Fixtures/real/`. Oczekiwany wynik wynika z etykiety w nazwie pliku
(`FixtureExpectation.swift`). Strojenie progów: `wrist-arena/docs/tuning.md`.
