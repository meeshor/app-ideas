// Indeks słownika parsera: nazwy (aliasy + formy) produktów i dań, jednostki, liczebniki, modyfikatory.
// Klucze bez polskich znaków (dopasowanie „bulka z szynka”), ale pamiętamy formę oryginalną,
// żeby rozróżnić dopasowanie dokładne od dopasowania „bez ogonków”.

import type { FoodDb } from './db.ts';
import type { Meal, SizeKey, UnitKey } from './types.ts';
import { keyOf, normalizeBasic } from './text.ts';

export interface NameEntry {
  kind: 'food' | 'dish';
  id: string;
  /** Klucze tokenów (bez polskich znaków). */
  keys: string[];
  /** Tokeny z polskimi znakami. */
  raw: string[];
  /** Nazwa/alias wpisany ręcznie (a nie forma wygenerowana). */
  isBase: boolean;
  /** Rekord użytkownika (dodany lub zmieniony) — pierwszeństwo. */
  user: boolean;
}

export interface AmountEntry {
  keys: string[];
  id: string;
  label: string;
  multiplier: number;
}

export interface Lexicon {
  /** Pierwszy klucz tokenu → wpisy (posortowane: dłuższe najpierw). */
  names: Map<string, NameEntry[]>;
  /** Wpisy wg liczby słów (dla dopasowania przybliżonego). */
  byWordCount: Map<number, NameEntry[]>;
  units: Map<string, UnitKey>;
  /** Formy jednostek z polskimi znakami — „paczki” (jednostka) vs „pączki” (produkt). */
  unitRaw: Set<string>;
  sizes: Map<string, SizeKey>;
  amounts: AmountEntry[];
  numbers: Map<string, number>;
  negations: Set<string>;
  markers: Set<string>;
  separators: Set<string>;
  fillers: Set<string>;
  mealWords: Map<string, Meal>;
  /** Wszystkie „słowa funkcyjne” — nie dopasowujemy ich przybliżenie do nazw produktów. */
  functionWords: Set<string>;
}

function splitWords(s: string): { keys: string[]; raw: string[] } {
  const raw = normalizeBasic(s).replace(/[-–—]/g, ' ').split(' ').filter(Boolean);
  return { raw, keys: raw.map((w) => keyOf(w)) };
}

export function buildLexicon(db: FoodDb): Lexicon {
  const names = new Map<string, NameEntry[]>();
  const byWordCount = new Map<number, NameEntry[]>();
  const seen = new Set<string>();
  const add = (kind: 'food' | 'dish', id: string, text: string, isBase: boolean, user: boolean) => {
    const { keys, raw } = splitWords(text);
    if (keys.length === 0) return;
    const sig = `${kind}|${id}|${raw.join(' ')}`;
    if (seen.has(sig)) return;
    seen.add(sig);
    const e: NameEntry = { kind, id, keys, raw, isBase, user };
    const list = names.get(keys[0]!) ?? [];
    list.push(e);
    names.set(keys[0]!, list);
    const wc = byWordCount.get(keys.length) ?? [];
    wc.push(e);
    byWordCount.set(keys.length, wc);
  };
  for (const f of db.foods.values()) {
    const user = (db.origin.get(`food:${f.id}`) ?? 'default') !== 'default';
    add('food', f.id, f.name, true, user);
    for (const a of f.aliases ?? []) add('food', f.id, a, true, user);
    for (const a of f.forms ?? []) add('food', f.id, a, false, user);
  }
  for (const d of db.dishes.values()) {
    const user = (db.origin.get(`dish:${d.id}`) ?? 'default') !== 'default';
    add('dish', d.id, d.name, true, user);
    for (const a of d.aliases ?? []) add('dish', d.id, a, true, user);
    for (const a of d.forms ?? []) add('dish', d.id, a, false, user);
  }
  for (const list of names.values()) list.sort((a, b) => b.keys.length - a.keys.length);

  const m = db.modifiers;
  const units = new Map<string, UnitKey>();
  const unitRaw = new Set<string>();
  for (const [k, u] of Object.entries(m.units)) {
    units.set(keyOf(k), k);
    for (const f of u.forms) {
      units.set(keyOf(f), k);
      unitRaw.add(normalizeBasic(f));
    }
  }
  const sizes = new Map<string, SizeKey>();
  for (const [k, s] of Object.entries(m.sizes) as [SizeKey, { forms: string[] }][]) for (const f of s.forms) sizes.set(keyOf(f), k);
  const amounts: AmountEntry[] = [];
  for (const a of m.amounts) for (const f of a.forms) amounts.push({ keys: splitWords(f).keys, id: a.id, label: a.label, multiplier: a.multiplier });
  amounts.sort((a, b) => b.keys.length - a.keys.length);
  const numbers = new Map(Object.entries(m.numberWords).map(([k, v]) => [keyOf(k), v]));
  const set = (xs: string[]) => new Set(xs.map((x) => keyOf(x)));
  const mealWords = new Map(Object.entries(m.mealWords).map(([k, v]) => [keyOf(k), v]));
  const lex: Lexicon = {
    names, byWordCount, units, unitRaw, sizes, amounts, numbers, mealWords,
    negations: set(m.negations),
    markers: set(m.attachMarkers),
    separators: set(m.separators),
    fillers: set(m.fillers),
    functionWords: new Set(),
  };
  for (const s of [units.keys(), sizes.keys(), numbers.keys(), lex.negations, lex.markers, lex.separators, lex.fillers, mealWords.keys()])
    for (const k of s) lex.functionWords.add(k);
  for (const a of amounts) for (const k of a.keys) lex.functionWords.add(k);
  return lex;
}
