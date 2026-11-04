# meeshApps: co jest potrzebne do sprzedaży w App Store

Stan na listopad 2026. Zasady Apple zmieniają się co kilka miesięcy, więc przed pierwszym wysłaniem aplikacji sprawdź aktualne pola w App Store Connect. To zestawienie nie jest poradą prawną ani podatkową.

## 1. Strona www (pola w App Store Connect)

| Pole | Czy wymagane | Nasza podstrona | Uwagi |
|---|---|---|---|
| Privacy Policy URL | **tak**, dla każdej aplikacji | `/privacy.html` | Wytyczna 5.1.1(i). Wymagana nawet, gdy gra nic nie zbiera. Musi też być dostępna z wnętrza aplikacji (np. w Ustawieniach gry). |
| Support URL | **tak** | `/support.html` | Musi prowadzić do realnego kontaktu (e-mail), nie tylko do FAQ. Recenzenci Apple to sprawdzają. |
| Marketing URL | nie | `/apps/<gra>.html` | Przydatne do linkowania z social mediów. |
| EULA / Terms of Use | nie, dopóki nie ma subskrypcji | `/terms.html` | Bez własnej EULA działa [standardowa EULA Apple](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/). Przy subskrypcjach (wytyczna 3.1.2) link do warunków musi być w aplikacji i w opisie. Nasza strona dokłada zasady bezpieczeństwa gier ruchowych. |
| Dane sprzedawcy (DSA) | **tak** przy sprzedaży w UE | `/legal.html` | Patrz punkt 2. |

## 2. Prawo UE i Polski

- **Status przedsiębiorcy (Akt o usługach cyfrowych, DSA).** Od lutego 2025 r. Apple usuwa z unijnego App Store aplikacje bez zadeklarowanego statusu. Kto sprzedaje płatne gry lub zakupy w aplikacji, jest przedsiębiorcą i musi podać adres, telefon i e-mail. Apple wyświetla je publicznie na karcie aplikacji w UE. Jeśli nie chcesz pokazywać adresu domowego, rozważ wirtualne biuro.
- **RODO.** Polityka prywatności musi wskazać administratora, cele i podstawy przetwarzania, odbiorców (Apple, dostawca poczty, hosting), okres przechowywania, prawa osoby i prawo skargi do UODO. Szablon w `site/privacy.html` to robi dla gier offline.
- **Prawa konsumenta i zwroty.** Sprzedawcą wobec klienta jest Apple (działa jako pośrednik/komisant), więc odstąpienie od umowy i zwroty obsługuje Apple. Na stronie wystarczy odesłać do [reportaproblem.apple.com](https://reportaproblem.apple.com).
- **Regulamin świadczenia usług drogą elektroniczną** (ustawa o świadczeniu usług drogą elektroniczną) jest potrzebny dopiero wtedy, gdy sam świadczysz usługi online: konta, własne serwery, czat. Gry offline z Game Center go nie wymagają.
- **Podatki.** Przychód z App Store trzeba rozliczyć w Polsce. Apple wypłaca pieniądze z Irlandii (Apple Distribution International) i sam rozlicza VAT od klientów. Forma (działalność nierejestrowana, JDG, spółka) zależy od skali. Porozmawiaj z księgową przed pierwszą wypłatą.

## 3. Konto Apple Developer

- **Apple Developer Program: 99 USD rocznie.**
- **Osoba fizyczna czy organizacja.** Jednoosobowa działalność (JDG) rejestruje się jako osoba fizyczna, więc w App Store jako sprzedawca widnieje imię i nazwisko. Żeby sprzedawcą było „meeshApps”, potrzebna jest osoba prawna (np. sp. z o.o.) z numerem D-U-N-S (bezpłatny, wydawany przez Dun & Bradstreet na wniosek przez Apple). Nazwa „meeshApps” może być marką w nazwie dewelopera na stronie i w grach niezależnie od tego.
- **Umowa Paid Applications, konto bankowe, formularz W-8BEN** (w App Store Connect, sekcja Business). Bez nich nie wystawisz płatnej gry ani zakupów w aplikacji.
- **App Store Small Business Program**: prowizja 15% zamiast 30%, jeśli przychód nie przekracza 1 mln USD rocznie. Trzeba się zgłosić osobno.

## 4. W aplikacji i w jej karcie w sklepie

- **Etykiety prywatności (App Privacy).** Przy grach offline bez analityki: „Data Not Collected”. Raporty awarii zbierane przez Apple nie wymagają deklaracji, ale SDK firm trzecich już tak.
- **Privacy Manifest** (`PrivacyInfo.xcprivacy`) z powodami użycia wymaganych API (np. UserDefaults, czas uruchomienia systemu).
- **Opisy uprawnień** w `Info.plist`: `NSMotionUsageDescription` (dane ruchu), `NSCameraUsageDescription` (tryb AR w Slingworks). Jeśli użyjesz HealthKit (np. tętno), polityka prywatności musi to opisać, a dane zdrowotne nie mogą służyć do reklam (wytyczna 5.1.3).
- **Kategoria wiekowa.** Nowa ankieta Apple z progami 4+, 9+, 13+, 16+, 18+.
- **Ekran bezpieczeństwa** przy pierwszym uruchomieniu gry ruchowej (wolna przestrzeń, zapięty pasek). Chroni graczy i zmniejsza ryzyko odpowiedzialności. Te same zasady są w `site/terms.html`.
- **Przywracanie zakupów**: przycisk „Restore Purchases”, jeśli są zakupy w aplikacji (wymóg Apple).
- **Usuwanie konta w aplikacji** (wytyczna 5.1.1(v)): obowiązkowe, jeśli dodasz konta użytkowników.
- **Materiały do karty**: ikona 1024 × 1024 px bez przezroczystości, zrzuty ekranu iPhone (6,9") i Apple Watch, opis, słowa kluczowe, opcjonalnie wideo.

## 5. Domena i poczta

- Domena: `meeshapps.com` lub `meeshapps.app` (dostępność do sprawdzenia).
- Hosting: GitHub Pages z własną domeną, za darmo. Folder `site/` jest gotowy do wrzucenia jako statyczna strona.
- Poczta: `support@`, `privacy@`, `hello@` jako aliasy przekierowujące na Twoją skrzynkę (większość rejestratorów robi to za darmo) albo pełna skrzynka (Proton, Zoho, Google Workspace).

## 6. Przed publikacją strony

1. Uzupełnij wszystkie pola oznaczone `<mark class="todo">` (dane sprzedawcy, adresy e-mail, daty).
2. Wybierz paletę, ustaw ją jako domyślną w `site/assets/style.css` i `site.js`, usuń pasek „Podgląd palety” z każdej podstrony.
3. Wybierz logo i ikonkę, zamień tekst w SVG na krzywe, podmień `site/assets/favicon.svg`.
4. Dla każdej nowej gry skopiuj `site/apps/cieciwa.html` i dodaj kafel na stronie głównej.
