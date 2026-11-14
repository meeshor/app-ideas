# Opóźnienie zegarek → telefon

## Dlaczego to mierzymy

Rozpoznawanie gestów odbywa się na zegarku, a na telefon idzie tylko zdarzenie (`ThrowEvent`).
W rzutkach animacja startuje dopiero po zdarzeniu, więc opóźnienie nie psuje gry, ale musi być
przewidywalne (ok. 100–300 ms jest akceptowalne). Gry „w moment” (odbijanie piłki) wymagałyby
synchronizacji zegarów i stempli czasu z zegarka. `ThrowEvent.watchTimestamp` jest na to gotowy.

## Metoda

Ekran **Czujniki (debug)** na iPhonie (WatchConnectivity, `sendMessageData`):

1. **RTT ping-pong.** Telefon wysyła `ping(t0)`. Zegarek odpowiada od razu na wątku
   WatchConnectivity (bez czekania na UI) `pong(t0, t1, t2)`, a telefon notuje `t3`.
   - RTT = (t3 − t0) − (t2 − t1)
   - przesunięcie zegarów = ((t1 − t0) + (t2 − t3)) / 2 (jak w NTP)

   Do przeliczania czasu bierzemy pomiar o najmniejszym RTT (`ClockSync`).
   Oba zegary to `systemUptime`, ta sama podstawa co `CMLogItem.timestamp`.
2. **Transport (w jedną stronę).** Przy włączonym podglądzie każda paczka próbek ma `sentAt`
   według zegara zegarka. Opóźnienie = odbiór na telefonie − `sentAt` przeliczone na zegar telefonu.
3. **Wiek próbki.** Odbiór − czas najnowszej próbki w paczce: transport plus czekanie na
   skompletowanie paczki (do 0,2 s przy 25 Hz). To górna granica dla podglądu na żywo, a nie dla rzutu.
4. **Zgubione wiadomości.** Luki w numerach `seq` (wspólny licznik nadawcy).

Przycisk **Kopiuj raport** kopiuje tabelę w formacie poniżej.

## Wyniki

Uzupełnić po pomiarze na urządzeniach (wklej raport z aplikacji).

| Warunki | Pomiar | n | min [ms] | mediana [ms] | p90 [ms] | max [ms] |
|---|---|---|---|---|---|---|
| _do uzupełnienia_ | RTT ping-pong | | | | | |
| | Transport (jedna strona) | | | | | |
| | Wiek próbki przy odbiorze | | | | | |

Warto zmierzyć w trzech warunkach:
- telefon obok zegarka, ekran zegarka włączony;
- telefon 3–5 m dalej (jak przy grze z TV);
- nadgarstek opuszczony, ekran zegarka wygaszony (sesja treningu aktywna).

## Wnioski dla gry

Do uzupełnienia po pomiarach. Robocza hipoteza: zdarzenie rzutu dociera w ok. 100–200 ms,
więc wystarczy krótka animacja „lotu” rzutki (~0,3 s), która maskuje opóźnienie.
