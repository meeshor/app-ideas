# Prawdziwe nagrania z zegarka

Wrzuć tu pliki `.wkrec` wyeksportowane z ekranu **Czujniki (debug)** (protokół:
[`wrist-arena/docs/recording-protocol.md`](../../../../../wrist-arena/docs/recording-protocol.md)).

`FlickFixtureTests` sam je znajdzie i sprawdzi według **etykiety w nazwie pliku**, np.
`flick_left_01.wkrec` → dokładnie 1 rzut, yaw mniejszy niż średnia z `flick_center_*`.
Reguły: `FixtureExpectation.swift`. Nieznana etykieta = plik pomijany (z ostrzeżeniem).
