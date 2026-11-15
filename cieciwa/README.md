# Cięciwa

Łucznictwo sterowane Apple Watch: iPhone w ręce łuku celuje, zegarek na ręce naciągającej rozpoznaje
naciąg, kotwicę (stabilność ręki) i puszczenie cięciwy. Prompt: [`prompty/01-lucznictwo-cieciwa.md`](../prompty/01-lucznictwo-cieciwa.md).

## Stan

Zrobiona jest **logika testowalna bez urządzenia** (odpowiednik M2 i rdzenia M3/M4 z promptu).
Aplikacji iOS/watchOS i grafiki (RealityKit) jeszcze nie ma.

| Część | Gdzie | Co robi |
|---|---|---|
| `DrawReleaseRecognizer` | `WristKit` | `idle → raised → drawing → anchored → released/cancelled`. Siła = impuls przyspieszenia w tył (bez całkowania pozycji), stabilność = RMS żyroskopu w oknie 0,5 s, podgląd ~20 Hz. Progi: `DrawTuning`. |
| Syntetyczne nagrania | `WristKit` (`SyntheticMotion`: `raiseArm`, `draw`, `anchor`, `release`) | 12 przypadków testowych: poprawny strzał (×10 ziaren), słaby naciąg, brak naciągu, anulowanie, drżenie, szarpnięcie bez naciągu, puszczenie bez kotwicy, długa kotwica, lewa ręka, dwa strzały, ręka opuszczona, podgląd. |
| `Ballistics` | `CieciwaCore` | Strzała z oporem kwadratowym i wiatrem (całkowanie co 0,5 ms), celownik ustawiany pod pełny naciąg na dystans. |
| `TargetFace` | `CieciwaCore` | 10 pierścieni + X (40/80/122 cm), strzała na linii liczy się wyżej. |
| `SwayModel` | `CieciwaCore` | Kołysanie celownika z stabilności, tętna i czasu trzymania (okno 2–4 s, potem zmęczenie). Deterministyczne w czasie: ta sama funkcja rysuje celownik na żywo i rozstrzyga strzał. |
| `ShotResolver`, `ShotHint` | `CieciwaCore` | Celowanie telefonem + kołysanie + balistyka → punkt, punkty, jedna wskazówka („puściłeś za wcześnie”, „ręka drżała”…). |
| `ArcheryRound`, `PersonalBests`, `DailyChallenge` | `CieciwaCore` | Serie po 3, rekordy per dystans, wyzwanie dnia z ziarna daty (dystans, wiatr, kołysanie takie same dla wszystkich). |

Wszystkie stałe fizyczne mają w kodzie źródło szacunku albo oznaczenie **DO STROJENIA**.

```sh
cd cieciwa/CieciwaCore && swift test   # działa na macOS i Linuksie
```

## Następne kroki (wymagają Xcode / urządzeń)

1. Aplikacja na zegarek: `DrawReleaseRecognizer` na żywo (wzorem `wrist-arena/App/Watch`), tętno z `HKWorkoutSession`
   wpisywane do `ShotRelease.heartRate`, haptyka przy kotwicy i puszczeniu.
2. iPhone: celowanie orientacją telefonu z kalibracją „patrz prosto i dotknij”, celownik pływający wg `SwayModel.offset`,
   tryb dotykowy (przeciągnięcie = naciąg). Scena 3D w RealityKit — prototyp i decyzja RealityKit vs Unity (prompt).
3. Strojenie na prawdziwej ręce: oś przedramienia (jak w Wrist Arena), `fullDrawImpulse`, progi kotwicy i puszczenia.
