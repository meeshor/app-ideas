// Źródło danych: modyfikatory (rozmiary, ilości), jednostki, liczebniki i słownik pomocniczy parsera.
// Formy jednostek: ręcznie + generowane (inflect) w scripts/build-data.ts.
// Wartości zapasowe jednostek (fallbackGrams) to typowe miary kuchenne — do strojenia.

import type { ModifiersData, UnitDef } from '../src/core/types.ts';

function u(label: string, forms: string[], o: Partial<UnitDef> = {}): UnitDef {
  return { label, forms, ...o };
}

export const MODIFIERS: ModifiersData = {
  sizes: {
    small: { label: 'mała', multiplier: 0.8, forms: ['mała', 'mały', 'małe', 'małą', 'małego', 'małej', 'małych', 'małym', 'małymi', 'malutka', 'malutki', 'malutkie', 'maleńka', 'mniejsza', 'mniejszy', 'mniejsze', 'mniejszą'] },
    standard: { label: 'standard', multiplier: 1, forms: ['średnia', 'średni', 'średnie', 'średnią', 'średniego', 'średniej', 'normalna', 'normalny', 'normalne', 'normalną', 'zwykła', 'zwykły', 'zwykłe', 'zwykłą', 'standardowa', 'standardowy', 'standardowe'] },
    large: { label: 'duża', multiplier: 1.2, forms: ['duża', 'duży', 'duże', 'dużą', 'dużego', 'dużej', 'dużych', 'dużym', 'dużymi', 'większa', 'większy', 'większe', 'większą', 'spora', 'spory', 'spore', 'sporą', 'sporego', 'sporej'] },
    huge: { label: 'ogromna', multiplier: 1.5, forms: ['ogromna', 'ogromny', 'ogromne', 'ogromną', 'ogromnego', 'ogromnej', 'wielka', 'wielki', 'wielkie', 'wielką', 'wielkiego', 'wielkiej', 'gigantyczna', 'gigantyczny', 'gigantyczne', 'olbrzymia', 'olbrzymi', 'olbrzymie', 'xxl'] },
  },
  amounts: [
    { id: 'lots', label: 'dużo', multiplier: 2, forms: ['dużo', 'duzo', 'dużą ilością', 'duża ilość', 'dużą ilość', 'sporo', 'mnóstwo', 'kupa', 'masa'] },
    { id: 'more', label: 'więcej', multiplier: 1.5, forms: ['więcej', 'extra', 'ekstra', 'dodatkowy', 'dodatkowa', 'dodatkowe', 'dodatkowym', 'dodatkową'] },
    { id: 'double', label: 'podwójnie', multiplier: 2, forms: ['podwójny', 'podwójna', 'podwójne', 'podwójną', 'podwójnym', 'podwójnie', 'dwa razy'] },
    { id: 'triple', label: 'potrójnie', multiplier: 3, forms: ['potrójny', 'potrójna', 'potrójne', 'potrójną', 'trzy razy'] },
    { id: 'little', label: 'mało', multiplier: 0.5, forms: ['mało', 'trochę', 'troszkę', 'małą ilością', 'mała ilość', 'mniej', 'odrobina', 'odrobiną', 'odrobinę', 'odrobiny', 'szczypta', 'szczyptą', 'kapka', 'kapką'] },
  ],
  negations: ['bez'],
  attachMarkers: ['z', 'ze', 'na'],
  separators: ['i', 'oraz', 'plus', 'a', 'potem', 'później', 'następnie', 'także', 'też', 'jeszcze', 'do', 'albo', 'lub'],
  fillers: [
    'zjadłem', 'zjadłam', 'zjadł', 'zjadła', 'zjedliśmy', 'jadłem', 'jadłam', 'jem', 'zjem', 'wypiłem', 'wypiłam', 'wypił', 'wypiła', 'piłem', 'piłam', 'pije', 'piję',
    'było', 'był', 'była', 'miałem', 'miałam', 'około', 'ok', 'chyba', 'coś', 'jakieś', 'jakiś', 'jakaś', 'tak', 'sobie',
    'na', 'w', 'we', 'ze', 'z', 'po', 'przed', 'dziś', 'dzisiaj', 'rano', 'wieczorem', 'wczoraj', 'potem', 'jeszcze', 'też', 'także', 'oraz', 'się',
    'śniadanie', 'śniadania', 'drugie', 'obiad', 'obiadu', 'kolacja', 'kolację', 'kolacji', 'przekąska', 'przekąskę', 'deser', 'lunch', 'podwieczorek',
    'mój', 'moja', 'moje', 'moją', 'domowy', 'domowa', 'domowe', 'domową', 'świeży', 'świeża', 'świeże', 'świeżą', 'ciepły', 'ciepła', 'zimny', 'zimna',
    'grilla', 'grillu', 'piekarnika', 'patelni', 'pieca', 'mikrofali', 'sklepu', 'restauracji', 'stołówki',
    'ugotowany', 'ugotowana', 'ugotowane', 'gotowany', 'gotowana', 'gotowane',
  ],
  numberWords: {
    jeden: 1, jedna: 1, jedno: 1, jedną: 1, jednego: 1, jednej: 1, jednym: 1,
    dwa: 2, dwie: 2, dwóch: 2, dwoma: 2, dwiema: 2, dwu: 2,
    trzy: 3, trzech: 3, trzema: 3,
    cztery: 4, czterech: 4, czterema: 4,
    pięć: 5, pięciu: 5, sześć: 6, sześciu: 6, siedem: 7, siedmiu: 7, osiem: 8, ośmiu: 8, dziewięć: 9, dziewięciu: 9, dziesięć: 10, dziesięciu: 10,
    pół: 0.5, połowa: 0.5, połowę: 0.5, połówka: 0.5, połówkę: 0.5, połowy: 0.5,
    półtora: 1.5, półtorej: 1.5,
    ćwierć: 0.25, ćwiartka: 0.25, ćwiartkę: 0.25,
    // „kilka” = 3, „parę” = 2 — umowne, do strojenia
    kilka: 3, kilku: 3, parę: 2, para: 2, pary: 2,
  },
  units: {
    g: u('g', ['g', 'gr', 'gram', 'gramy', 'gramów', 'grama', 'gramow'], { grams: 1 }),
    dag: u('dag', ['dag', 'dkg', 'deko', 'deka', 'dekagram', 'dekagramów'], { grams: 10 }),
    kg: u('kg', ['kg', 'kilo', 'kilogram', 'kilograma', 'kilogramy', 'kilogramów'], { grams: 1000 }),
    ml: u('ml', ['ml', 'mililitr', 'mililitrów', 'mililitry'], { ml: 1 }),
    l: u('l', ['l', 'litr', 'litra', 'litry', 'litrów'], { ml: 1000 }),
    sztuka: u('szt.', ['szt', 'sztuka', 'sztuki', 'sztuk', 'sztukę', 'sztuką', 'sztuce', 'sztukami', 'cały', 'cała', 'całe', 'całą', 'całego', 'całej', 'całych'], { fallbackGrams: 100, plural: 'szt.', genitivePlural: 'szt.' }),
    porcja: u('porcja', ['porcja', 'porcje', 'porcji', 'porcję', 'porcją', 'porcyjka', 'porcyjkę', 'porcjami', 'porcyjki'], { plural: 'porcje', genitivePlural: 'porcji' }),
    plaster: u('plaster', ['plaster', 'plastry', 'plastra', 'plastrem', 'plastrów', 'plastrami', 'plasterek', 'plasterki', 'plasterka', 'plasterkiem', 'plasterków', 'plasterkami'], { fallbackGrams: 15, plural: 'plastry', genitivePlural: 'plastrów' }),
    kromka: u('kromka', ['kromka', 'kromki', 'kromek', 'kromkę', 'kromką', 'kromkami', 'kromeczka', 'kromeczki', 'pajda', 'pajdę', 'pajdy'], { fallbackGrams: 35, plural: 'kromki', genitivePlural: 'kromek' }),
    kawalek: u('kawałek', ['kawałek', 'kawałki', 'kawałka', 'kawałkiem', 'kawałków', 'kawałkami', 'kawałeczek', 'kawałeczki', 'kawałeczka', 'kęs', 'kęsy'], { fallbackGrams: 50, plural: 'kawałki', genitivePlural: 'kawałków' }),
    lyzka: u('łyżka', ['łyżka', 'łyżki', 'łyżek', 'łyżkę', 'łyżką', 'łyżkami', 'łyżce', 'chochelka'], { fallbackGrams: 15, plural: 'łyżki', genitivePlural: 'łyżek' }),
    lyzeczka: u('łyżeczka', ['łyżeczka', 'łyżeczki', 'łyżeczek', 'łyżeczkę', 'łyżeczką', 'łyżeczkami', 'łyżeczce'], { fallbackGrams: 5, plural: 'łyżeczki', genitivePlural: 'łyżeczek' }),
    szklanka: u('szklanka', ['szklanka', 'szklanki', 'szklanek', 'szklankę', 'szklanką', 'szklankami', 'szklaneczka'], { ml: 250, plural: 'szklanki', genitivePlural: 'szklanek' }),
    kubek: u('kubek', ['kubek', 'kubki', 'kubka', 'kubków', 'kubkiem', 'kubeczek', 'kubeczka', 'kubkami'], { ml: 250, plural: 'kubki', genitivePlural: 'kubków' }),
    filizanka: u('filiżanka', ['filiżanka', 'filiżanki', 'filiżanek', 'filiżankę', 'filiżanką'], { ml: 150, plural: 'filiżanki', genitivePlural: 'filiżanek' }),
    talerz: u('talerz', ['talerz', 'talerze', 'talerza', 'talerzy', 'talerzem', 'talerzyk', 'talerzyka', 'talerzami'], { fallbackGrams: 300, plural: 'talerze', genitivePlural: 'talerzy' }),
    miska: u('miska', ['miska', 'miski', 'misek', 'miskę', 'miską', 'miseczka', 'miseczkę', 'miseczki', 'michę', 'micha'], { fallbackGrams: 300, plural: 'miski', genitivePlural: 'misek' }),
    chochla: u('chochla', ['chochla', 'chochle', 'chochli', 'chochlę', 'chochlą'], { fallbackGrams: 150, plural: 'chochle', genitivePlural: 'chochli' }),
    garsc: u('garść', ['garść', 'garście', 'garści', 'garścią', 'garstka', 'garstkę', 'garstki', 'garśćmi'], { fallbackGrams: 30, plural: 'garście', genitivePlural: 'garści' }),
    opakowanie: u('opakowanie', ['opakowanie', 'opakowania', 'opakowań', 'paczka', 'paczki', 'paczkę', 'paczek', 'paczuszka', 'saszetka', 'saszetki', 'saszetkę'], { fallbackGrams: 100, plural: 'opakowania', genitivePlural: 'opakowań' }),
    puszka: u('puszka', ['puszka', 'puszki', 'puszek', 'puszkę', 'puszką', 'puszeczka'], { ml: 330, plural: 'puszki', genitivePlural: 'puszek' }),
    butelka: u('butelka', ['butelka', 'butelki', 'butelek', 'butelkę', 'butelką', 'buteleczka', 'flaszka', 'flaszkę'], { ml: 500, plural: 'butelki', genitivePlural: 'butelek' }),
    kieliszek: u('kieliszek', ['kieliszek', 'kieliszki', 'kieliszka', 'kieliszków', 'lampka', 'lampkę', 'lampki', 'kielonek', 'kielicha'], { ml: 100, plural: 'kieliszki', genitivePlural: 'kieliszków' }),
    kufel: u('kufel', ['kufel', 'kufle', 'kufla', 'kufli'], { ml: 500, plural: 'kufle', genitivePlural: 'kufli' }),
    lisc: u('liść', ['liść', 'liście', 'liści', 'listek', 'listki', 'listków', 'liśćmi'], { fallbackGrams: 10, plural: 'liście', genitivePlural: 'liści' }),
    kostka: u('kostka', ['kostka', 'kostki', 'kostek', 'kostkę', 'kostką'], { fallbackGrams: 5, plural: 'kostki', genitivePlural: 'kostek' }),
    rzad: u('rząd', ['rząd', 'rzędy', 'rzędu', 'rzędów', 'rządek', 'rządki'], { fallbackGrams: 25, plural: 'rzędy', genitivePlural: 'rzędów' }),
    tabliczka: u('tabliczka', ['tabliczka', 'tabliczki', 'tabliczek', 'tabliczkę', 'tabliczką'], { fallbackGrams: 100, plural: 'tabliczki', genitivePlural: 'tabliczek' }),
    galka: u('gałka', ['gałka', 'gałki', 'gałek', 'gałkę', 'gałką'], { fallbackGrams: 50, plural: 'gałki', genitivePlural: 'gałek' }),
    kulka: u('kulka', ['kulka', 'kulki', 'kulek', 'kulkę', 'kulką'], { fallbackGrams: 30, plural: 'kulki', genitivePlural: 'kulek' }),
    zabek: u('ząbek', ['ząbek', 'ząbki', 'ząbka', 'ząbków', 'ząbkiem'], { fallbackGrams: 5, plural: 'ząbki', genitivePlural: 'ząbków' }),
    torebka: u('torebka', ['torebka', 'torebki', 'torebek', 'torebkę', 'torebką', 'woreczek', 'woreczki', 'woreczka'], { fallbackGrams: 250, plural: 'torebki', genitivePlural: 'torebek' }),
    kisc: u('kiść', ['kiść', 'kiście', 'kiści'], { fallbackGrams: 150, plural: 'kiście', genitivePlural: 'kiści' }),
  },
  mealWords: {
    śniadanie: 'breakfast', śniadania: 'breakfast', śniadaniu: 'breakfast',
    obiad: 'lunch', obiadu: 'lunch', obiedzie: 'lunch', lunch: 'lunch',
    kolacja: 'dinner', kolację: 'dinner', kolacji: 'dinner',
    przekąska: 'snack', przekąskę: 'snack', deser: 'snack', podwieczorek: 'snack',
  },
};
