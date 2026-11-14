# Protokół nagrań do testów (przed M2)

Nagrania z prawdziwego zegarka posłużą jako przypadki testowe dla `FlickThrowRecognizer`.
Nagrywaj z iPhone'a: **Czujniki (debug)** → wpisz etykietę → **Nagrywaj na zegarku**, potem
**Zatrzymaj**. Plik sam trafi na telefon (lista „Nagrania”), a eksport idzie przez przycisk udostępniania.

Każde nagranie: ok. 1 s spokojnej ręki, gest, ok. 1 s spokoju. Jedno nagranie = jeden przypadek
(wyjątek: `flick_series`).

| Etykieta | Co zrobić | Oczekiwany wynik |
|---|---|---|
| `flick_center_01..03` | normalny rzut w środek tarczy | 1 rzut, yaw ≈ 0, pitch ≈ 0 |
| `flick_left_01`, `flick_right_01` | rzut wyraźnie w lewo / w prawo | 1 rzut, yaw < 0 / > 0 |
| `flick_high_01`, `flick_low_01` | rzut wyraźnie w górę / w dół | 1 rzut, pitch > 0 / < 0 |
| `flick_weak_01` | bardzo słaby, „leniwy” ruch | 0 rzutów albo niska prędkość |
| `flick_strong_01` | mocny rzut | 1 rzut, wysoka prędkość |
| `flick_twist_01` | rzut ze skrętem nadgarstka | 1 rzut, duży `spin` |
| `flick_jerky_01` | szarpnięty, nierówny rzut | 1 rzut, wysoki `jerk` |
| `flick_series_01` | 3 rzuty z przerwami ok. 2 s | 3 rzuty |
| `noise_scratch_01` | podrapanie się po głowie | 0 rzutów |
| `noise_wave_01` | machnięcie ręką „cześć” | 0 rzutów |
| `noise_lower_01` | powolne opuszczenie ręki | 0 rzutów |
| `idle_tremor_01` | 5 s trzymania ręki w pozycji do rzutu | 0 rzutów |
| `flick_lefthand_01` | rzut lewą ręką (zegarek na lewym nadgarstku) | 1 rzut, kąty jak prawą |

Wyeksportowane pliki `.wkrec` wrzuć do `WristKit/Tests/WristKitTests/Fixtures/real/`
(commit albo przesłanie w dowolny sposób). Etykieta w nazwie pliku = nazwa przypadku testowego.
