# Prompt startowy: „Slingworks” — proca 3D z destrukcją, sterowana Apple Watch

> Skopiuj wszystko poniżej linii do nowej sesji Claude Code w pustym repozytorium.

---

Budujemy grę mobilną **„Slingworks”** (nazwa robocza): fizyczna gra z destrukcją w 3D, w której **naciągamy procę ruchem ręki z Apple Watch**, a na iPhonie oglądamy, jak konstrukcje się rozpadają. Gra ma **własny, oryginalny świat**: np. skrzaty-złomiarze bronią chwiejnych wież zbudowanych ze złomu, desek i kamieni, a gracz strzela różnymi pociskami (kamień, kula bilardowa, „bomba” z puszki, rzep, który się przykleja). Nie kopiujemy żadnej istniejącej gry: ani postaci, ani grafiki, ani układu poziomów.

## Cel produktu

- Największa przyjemność: **chwila po strzale**, czyli powtórka w zwolnionym tempie z różnych kamer i satysfakcjonująca destrukcja. To ma się nadawać do nagrania i wrzucenia na social media (przycisk „zapisz powtórkę jako wideo”).
- Dwa sposoby trzymania:
  1. **Tryb „widełki”:** telefon w jednej ręce jest procą i celownikiem (żyroskop telefonu = kierunek), zegarek na drugiej ręce rozpoznaje naciąg i puszczenie gumy.
  2. **Tryb „stół AR”:** poziom stoi na stole lub podłodze (ARKit), można go obejść i strzelać z dowolnego miejsca.
- Musi działać **bez zegarka**: klasyczne przeciąganie palcem jak w procy dotykowej.

## Platforma i stos

- iOS 18+ / watchOS 11+.
- Silnik gry: **Unity 6 (LTS)** z fizyką PhysX. Uzasadnienie: dojrzałe narzędzia do fizyki brył, fracture/prefabów, ARFoundation, nagrywanie wideo, łatwiejsze projektowanie poziomów i przyszły port na Androida i Wear OS.
- Aplikacja na zegarek musi być **natywna (Swift)**, bo Unity jej nie zbuduje. Most: natywny plugin iOS (Swift lub Obj-C) z `WCSession`, wystawiony do C# przez `[DllImport]` / `UnitySendMessage`. Opisz, jak dodajesz target watchOS do projektu Xcode generowanego przez Unity (post-build script), żeby build był powtarzalny.
- Jeśli istnieje już pakiet `WristKit` (Swift Package z rozpoznawaniem gestów naciągu i zwolnienia z innej mojej gry), zapytaj mnie o niego i użyj go. Jeśli nie, zbuduj go wg sekcji niżej.

## WristKit — rozpoznawanie gestu procy (na zegarku)

- Core Motion ~100 Hz, `HKWorkoutSession` dla pracy w tle z opuszczonym nadgarstkiem.
- Maszyna stanów `idle → gripping → pulling → holding → released / cancelled`.
  - **Siła naciągu:** nie całkujemy pozycji, bo dryfuje. Używamy heurystyki: czas i intensywność ruchu wstecz wzdłuż osi przedramienia plus zmiana pochylenia przedramienia. Mapowanie na 0…1 z krzywą do strojenia.
  - **Odchylenie pionowe** (nadgarstek wyżej lub niżej przy puszczeniu) może korygować kąt strzału o ±kilka stopni. Ma to być opcjonalne i domyślnie wyłączone.
  - **Puszczenie:** skok przyspieszenia lub otwarcie dłoni (gwałtowny ruch nadgarstka). Alternatywa dostępności: tap na zegarku.
- Na telefon idą tylko zdarzenia z parametrami i stemplem czasu zegarka oraz podgląd siły naciągu ~20 Hz, żeby guma na ekranie „rozciągała się” na żywo. Haptyka na zegarku rośnie z naciągiem.
- `MotionRecorder` / `MotionReplayer` do testów bez urządzenia (symulator nie ma czujników) plus syntetyczne nagrania w testach.

## Mechanika i zawartość MVP

- Pociski MVP: kamień (standard), ciężka kula (przebija), puszka (wybucha po tapnięciu w locie). Gracz wybiera kolejność przed poziomem.
- Konstrukcje z prefabów: deska, belka, kamień, szkło, beczka wybuchowa, każdy materiał z własną wytrzymałością, masą i dźwiękiem. Elementy pękają na prefabrykowane kawałki (bez fracture w czasie rzeczywistym w MVP).
- Cel poziomu: strącić wszystkich skrzatów albo zniszczyć X% konstrukcji. 1–3 gwiazdki za liczbę pocisków.
- **15 poziomów MVP** w jednym świecie, z rosnącą trudnością. Poziomy jako dane (ScriptableObject / JSON), żebym mógł je edytować.
- Powtórka: bufor stanu fizyki z ostatnich ~6 s, odtwarzanie w slow-mo z 2–3 kamer, eksport do wideo (ReplayKit lub nagrywanie klatek).
- Wydajność: stabilne 60 fps na iPhone 13 przy ~150 aktywnych bryłach. Usypianie brył, limity, pooling odłamków. Dodaj tryb benchmarku.

## Kamienie milowe

1. **M0 — Szkielet:** projekt Unity + natywny plugin + target watchOS, skrypt budujący wszystko z linii poleceń, testy EditMode dla logiki punktacji i ładowania poziomów.
2. **M1 — Fizyka bez zegarka:** jeden poziom, strzał dotykiem, destrukcja, punktacja, benchmark wydajności.
3. **M2 — Zegarek:** WristKit z testami na nagraniach, most WatchConnectivity, ekran debug z wykresami ruchu i pomiarem opóźnienia, tryb „widełki”.
4. **M3 — Powtórki:** slow-mo, kamery, eksport wideo.
5. **M4 — Tryb AR:** stawianie poziomu na powierzchni, skalowanie, okluzja (jeśli urządzenie wspiera LiDAR).
6. **M5 — MVP:** 15 poziomów, 3 pociski, onboarding i kalibracja, zapis postępu, Game Center.

Po każdym kamieniu: podsumowanie, co działa, co wymaga testu na fizycznym urządzeniu i co dokładnie mam sprawdzić.

## Zasady pracy

- Najpierw plan (struktura repo, sposób integracji watchOS z buildem Unity, ryzyka) i czekaj na moją akceptację.
- Stałe gestów i fizyki w jednym miejscu konfiguracyjnym, oznaczone „do strojenia”.
- Placeholderowa grafika z prostych brył i materiałów (bez assetów o niejasnej licencji). Jeśli korzystasz z darmowych assetów, zapisz licencje w `ASSETS_LICENSES.md`.
- Krótkie, opisowe commity, README z instrukcją builda na urządzenie.
