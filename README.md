# app-ideas

Pomysły na gry ruchowe na telefon + zegarek.

- [`analiza.md`](analiza.md): ocena 8 pomysłów (sens, konkurencja, ryzyko), tabela i wybór trójki.
- Prompty startowe do realizacji:
  1. [`prompty/01-lucznictwo-cieciwa.md`](prompty/01-lucznictwo-cieciwa.md): łucznictwo z Watchem (flagowiec)
  2. [`prompty/02-proca-3d-slingworks.md`](prompty/02-proca-3d-slingworks.md): proca 3D z destrukcją i trybem AR na stole
  3. [`prompty/03-pakiet-wrist-arena.md`](prompty/03-pakiet-wrist-arena.md): pakiet sportów z nadgarstka (rzutki, karne w ręcznej, …)

## Projekty

- [`WristKit/`](WristKit/): wspólny Swift Package (ruch z Apple Watch, nagrania, rozpoznawanie gestów, transport zdarzeń). Używają go wszystkie trzy gry.
- [`wrist-arena/`](wrist-arena/): **Wrist Arena**, pakiet sportów z nadgarstka (iOS + watchOS). W toku: M0 (szkielet).

## Kod

- [`wrist-arena/`](wrist-arena/): Wrist Arena (rzutki, rzut karny w ręcznej), iOS + watchOS. Stan i instrukcje: [`wrist-arena/README.md`](wrist-arena/README.md).
- [`cieciwa/`](cieciwa/): Cięciwa (łucznictwo), na razie logika i rozpoznawanie gestu: [`cieciwa/README.md`](cieciwa/README.md).
- [`WristKit/`](WristKit/): wspólny pakiet ruchu i gestów z Apple Watch (rzut z nadgarstka, rzut nad głową ze zwodem, naciąg i puszczenie cięciwy).
