// Półautomatyczne formy odmiany polskich nazw produktów — proste reguły końcówek.
//
// Cel: wygenerować formy, w jakich nazwa realnie pojawia się w opisie posiłku
// („bułkę”, „bułki”, „z bułką”, „2 bułki”, „5 bułek”, „z szynką”, „plaster szynki”).
// Reguły celowo przegenerowują (lepiej mieć nieistniejącą formę niż brakującą);
// kolizje między produktami wykrywa test danych. Formy nieregularne dopisuje się ręcznie
// w data-src (pole `forms`). To nie jest pełna morfologia — patrz docs/parser.md.
//
// Założenie zapisu nazw wielowyrazowych: rzeczownik pierwszy, potem przymiotniki
// („bułka żytnia”, „ser żółty”), dalej ewentualnie fraza z przyimkiem, która się nie odmienia
// („pierś z kurczaka”). Dla nazw „rzeczownik + przymiotnik” generujemy też szyk odwrotny („żytnia bułka”).

type Slot = 'nom' | 'gen' | 'acc' | 'ins' | 'loc' | 'nomPl' | 'genPl' | 'insPl' | 'locPl';
const SLOTS: Slot[] = ['nom', 'gen', 'acc', 'ins', 'loc', 'nomPl', 'genPl', 'insPl', 'locPl'];
type Gender = 'f' | 'm' | 'n' | 'pl';
type Forms = Record<Slot, string[]>;

const PREPOSITIONS = new Set(['z', 'ze', 'w', 'we', 'na', 'do', 'od', 'po', 'bez', 'i']);

/** Słowa nieodmienne (zapożyczenia). */
const INDECLINABLE = new Set([
  'kiwi', 'sushi', 'spaghetti', 'spagetti', 'salami', 'musli', 'muesli', 'latte', 'cappuccino', 'espresso',
  'tofu', 'menu', 'hot', 'dog', 'cola', 'zero', 'bolognese', 'feta', 'mozzarella', 'parmezan', 'light',
  'fit', 'mini', 'max', 'kebab', 'cheeseburger', 'tortilla', 'wrap', 'avocado',
]);

const ADJ_ENDINGS = [
  'owy', 'owa', 'owe', 'ny', 'na', 'ne', 'ni', 'nia', 'nie', 'ski', 'ska', 'skie', 'cki', 'cka', 'ckie',
  'ły', 'ła', 'łe', 'ty', 'ta', 'te', 'wy', 'wa', 'we', 'zy', 'rzy', 'ry', 'ra', 're', 'ki', 'ka', 'kie',
  'gi', 'ga', 'gie', 'ąca', 'ący', 'ące', 'ony', 'ona', 'one', 'iony', 'iona', 'ione', 'sty', 'sta', 'ste', 'dy', 'da', 'de',
];

function isAdjectiveLike(w: string): boolean {
  return ADJ_ENDINGS.some((e) => w.endsWith(e)) && w.length > 3;
}

function emptyForms(): Forms {
  return { nom: [], gen: [], acc: [], ins: [], loc: [], nomPl: [], genPl: [], insPl: [], locPl: [] };
}

function fixed(w: string): Forms {
  const f = emptyForms();
  for (const s of SLOTS) f[s].push(w);
  return f;
}

const SOFT_2 = ['rz', 'sz', 'cz', 'dz', 'dź'];
const SOFT_1 = ['ż', 'c', 'j', 'l', 'ś', 'ć', 'ń', 'ź'];

function endsSoft(stem: string): boolean {
  return SOFT_2.some((e) => stem.endsWith(e)) || SOFT_1.some((e) => stem.endsWith(e));
}
function endsKG(stem: string): boolean {
  return /[kg]$/.test(stem);
}
const VOWELS = /[aeiouyąęó]$/;

/** Twarda spółgłoska + „e” w miejscowniku: „ser” → „serze”, „jogurt” → „jogurcie”. */
function palatalLoc(stem: string): string | null {
  const map: [string, string][] = [
    ['st', 'ście'], ['sł', 'śle'], ['zd', 'ździe'], ['ch', 'sze'], ['r', 'rze'], ['t', 'cie'], ['d', 'dzie'],
    ['s', 'sie'], ['z', 'zie'], ['n', 'nie'], ['b', 'bie'], ['p', 'pie'], ['w', 'wie'], ['m', 'mie'],
    ['f', 'fie'], ['ł', 'le'], ['k', 'ce'], ['g', 'dze'],
  ];
  for (const [end, rep] of map) if (stem.endsWith(end)) return stem.slice(0, -end.length) + rep;
  return null;
}

/** Dopełniacz l. mn. z „ruchomym e”: „bułk” → „bułek”, „jajk” → „jajek”. */
function genPlFleeting(stem: string): string {
  if (/[^aeiouyąęó][kc]$/.test(stem) && stem.length > 2) return stem.slice(0, -1) + 'e' + stem.slice(-1);
  return stem;
}

function nounFemA(w: string): Forms {
  const f = emptyForms();
  const s = w.slice(0, -1);
  f.nom.push(w);
  let gen: string;
  if (s.endsWith('i')) gen = s; // brzoskwinia → brzoskwini
  else if (endsKG(s) || /[lj]$/.test(s)) gen = s + 'i';
  else gen = s + 'y';
  f.gen.push(gen);
  f.nomPl.push(gen);
  f.acc.push(s + 'ę');
  f.ins.push(s + 'ą');
  const loc = /[lj]$/.test(s) || endsSoft(s) || s.endsWith('i') ? gen : palatalLoc(s) ?? gen;
  f.loc.push(loc);
  f.genPl.push(s.endsWith('i') ? s.slice(0, -1) : genPlFleeting(s));
  f.insPl.push(s + 'ami');
  f.locPl.push(s + 'ach');
  return f;
}

function nounNeutO(w: string): Forms {
  const f = emptyForms();
  const s = w.slice(0, -1);
  f.nom.push(w);
  f.acc.push(w);
  f.gen.push(s + 'a');
  f.nomPl.push(s + 'a');
  f.ins.push(s + (endsKG(s) ? 'iem' : 'em'));
  f.loc.push(s + 'u');
  if (!endsKG(s) && !s.endsWith('ch')) {
    const l = palatalLoc(s);
    if (l) f.loc.push(l);
  }
  f.genPl.push(genPlFleeting(s));
  f.insPl.push(s + 'ami');
  f.locPl.push(s + 'ach');
  return f;
}

function nounNeutE(w: string): Forms {
  const f = emptyForms();
  const s = w.slice(0, -1);
  f.nom.push(w);
  f.acc.push(w);
  f.gen.push(s + 'a');
  f.nomPl.push(s + 'a');
  f.ins.push(s + 'em');
  f.loc.push(s + 'u');
  f.genPl.push(s);
  f.insPl.push(s + 'ami');
  f.locPl.push(s + 'ach');
  return f;
}

function nounMasc(w: string): Forms {
  const f = emptyForms();
  let s = w.replace(/ó([^aeiouyąęó]+)$/, 'o$1'); // twaróg → twarog, napój → napoj
  if (/[^aeiouyąęó]ek$/.test(w) && w.length > 3) s = w.slice(0, -2) + 'k'; // ogórek → ogórk
  else if (/[^aeiouyąęó]ec$/.test(w) && w.length > 3) s = w.slice(0, -2) + 'c'; // smalec → smalc
  f.nom.push(w);
  f.acc.push(w, s + 'a');
  f.gen.push(s + 'a', s + 'u');
  f.ins.push(s + (endsKG(s) ? 'iem' : 'em'));
  if (endsKG(s) || s.endsWith('ch') || endsSoft(s)) f.loc.push(s + 'u');
  else {
    const l = palatalLoc(s);
    if (l) f.loc.push(l);
    f.loc.push(s + 'u');
  }
  const pl = endsKG(s) ? s + 'i' : endsSoft(s) ? s + 'e' : s + 'y';
  f.nomPl.push(pl);
  f.genPl.push(s + 'ów');
  if (endsSoft(s)) f.genPl.push(s + 'y', s + 'i');
  f.insPl.push(s + 'ami');
  f.locPl.push(s + 'ach');
  return f;
}

/** Rzeczownik w liczbie mnogiej („pierogi”, „frytki”, „maliny”) + zgadywana liczba pojedyncza. */
function nounPlural(w: string): Forms {
  const f = emptyForms();
  const s = w.slice(0, -1); // ziemniak, frytk, malin, pierog
  const softS = w.endsWith('ie') ? w.slice(0, -2) : null; // „naleśniki”? (nie) / „jajecznice”? — rzadkie
  const base = softS ?? s;
  f.nomPl.push(w);
  f.acc.push(w);
  f.genPl.push(base + 'ów', genPlFleeting(base));
  f.insPl.push(base + 'ami');
  f.locPl.push(base + 'ach');
  // liczba pojedyncza: męska („ziemniak”) albo żeńska („frytka”, „malina”)
  if (!VOWELS.test(base)) {
    const masc = nounMasc(genPlFleeting(base) === base ? base : genPlFleeting(base));
    const fem = nounFemA(base + 'a');
    for (const slot of ['nom', 'gen', 'ins', 'loc'] as Slot[]) {
      f[slot].push(...masc[slot], ...fem[slot]);
    }
    f.acc.push(...fem.acc, ...masc.acc);
  }
  return f;
}

function nounForms(w: string): { forms: Forms; gender: Gender } {
  if (INDECLINABLE.has(w) || w.length <= 2) return { forms: fixed(w), gender: 'm' };
  if (w.endsWith('a')) return { forms: nounFemA(w), gender: 'f' };
  if (w.endsWith('o')) return { forms: nounNeutO(w), gender: 'n' };
  if (w.endsWith('e') || w.endsWith('ę')) return { forms: nounNeutE(w), gender: 'n' };
  if (w.endsWith('y') || w.endsWith('i')) return { forms: nounPlural(w), gender: 'pl' };
  if (/[aeiouyąęó]$/.test(w)) return { forms: fixed(w), gender: 'm' };
  return { forms: nounMasc(w), gender: 'm' };
}

/** Przymiotnik zgodny z rodzajem rzeczownika. */
function adjForms(w: string, gender: Gender): Forms {
  if (INDECLINABLE.has(w)) return fixed(w);
  let stem: string;
  let type: 'hard' | 'kg' | 'soft';
  if (/(ia|ie)$/.test(w) && !/[kg]i[ae]$/.test(w)) {
    stem = w.slice(0, -2);
    type = 'soft';
  } else if (/[kg](i|a|ie)$/.test(w)) {
    stem = w.replace(/(ie|i|a)$/, '');
    type = 'kg';
  } else if (w.endsWith('i')) {
    stem = w.slice(0, -1);
    type = 'soft';
  } else {
    stem = w.slice(0, -1);
    type = 'hard';
  }
  const i = type === 'hard' ? 'y' : 'i';
  const e = type === 'hard' ? 'e' : 'ie'; // przed „e”: twardy „-e”, miękki/k,g „-ie”
  const a = type === 'soft' ? 'ia' : 'a'; // przed „a/ą”: tylko miękki dostaje „i”
  const aa = type === 'soft' ? 'ią' : 'ą';
  const fem = { nom: stem + a, gen: stem + e + 'j', acc: stem + aa };
  const mascNom = stem + i;
  const neutNom = stem + e;
  const mGen = stem + e + 'go';
  const mIns = stem + i + 'm';
  const f = emptyForms();
  const add = (g: Gender) => {
    if (g === 'f') {
      f.nom.push(fem.nom);
      f.gen.push(fem.gen);
      f.loc.push(fem.gen);
      f.acc.push(fem.acc);
      f.ins.push(fem.acc);
    } else {
      f.nom.push(g === 'n' ? neutNom : mascNom);
      f.acc.push(g === 'n' ? neutNom : mascNom, mGen);
      f.gen.push(mGen);
      f.ins.push(mIns);
      f.loc.push(mIns);
    }
  };
  if (gender === 'pl') {
    add('f');
    add('m');
  } else add(gender);
  f.nomPl.push(neutNom);
  f.genPl.push(stem + i + 'ch');
  f.insPl.push(stem + i + 'mi');
  f.locPl.push(stem + i + 'ch');
  return f;
}

function cartesian(parts: string[][]): string[] {
  let acc: string[] = [''];
  for (const p of parts) {
    const next: string[] = [];
    for (const a of acc) for (const b of p) next.push(a ? `${a} ${b}` : b);
    acc = next;
  }
  return acc;
}

/**
 * Formy frazy (nazwy produktu): rzeczownik pierwszy + przymiotniki, fraza z przyimkiem bez zmian.
 * Zwraca posortowaną listę unikalnych form (z formą bazową).
 */
export function inflectPhrase(phrase: string): string[] {
  const words = phrase.normalize('NFC').toLowerCase().trim().split(/\s+/).filter(Boolean);
  if (words.length === 0) return [];
  const prepIdx = words.findIndex((w, i) => i > 0 && PREPOSITIONS.has(w));
  const inflected = prepIdx === -1 ? words : words.slice(0, prepIdx);
  const tail = prepIdx === -1 ? [] : words.slice(prepIdx);
  if (words.length === 1 && isAdjectiveLike(words[0]!) && !INDECLINABLE.has(words[0]!)) {
    // nazwa-przymiotnik („pomidorowa”, „schabowy”, „ruskie”): odmiana przymiotnikowa + rzeczownikowa (na wszelki wypadek)
    const w = words[0]!;
    const g: Gender = w.endsWith('a') ? 'f' : w.endsWith('e') ? 'pl' : 'm';
    const out = new Set<string>([w]);
    for (const f of [adjForms(w, g), nounForms(w).forms]) for (const slot of SLOTS) for (const x of f[slot]) out.add(x);
    return [...out].sort((a, b) => a.localeCompare(b, 'pl'));
  }
  const head = nounForms(inflected[0]!);
  const perWord: Forms[] = [head.forms];
  for (const w of inflected.slice(1)) perWord.push(isAdjectiveLike(w) ? adjForms(w, head.gender) : fixed(w));
  const out = new Set<string>([words.join(' ')]);
  const reversible = inflected.length === 2 && tail.length === 0 && isAdjectiveLike(inflected[1]!);
  for (const slot of SLOTS) {
    const parts = perWord.map((f) => [...new Set(f[slot])]);
    if (parts.some((p) => p.length === 0)) continue;
    for (const c of cartesian(parts)) out.add(tail.length ? `${c} ${tail.join(' ')}` : c);
    if (reversible) for (const c of cartesian([parts[1]!, parts[0]!])) out.add(c);
  }
  return [...out].filter((x) => x.length > 0).sort((a, b) => a.localeCompare(b, 'pl'));
}

/** Formy dla listy nazw (alias + synonimy), bez duplikatów. */
export function inflectAll(names: readonly string[]): string[] {
  const out = new Set<string>();
  for (const n of names) for (const f of inflectPhrase(n)) out.add(f);
  return [...out].sort((a, b) => a.localeCompare(b, 'pl'));
}
