// Osobiste definicje: „Zapamiętaj jako moje” i produkty dodawane przez użytkownika.

import { expandItem, componentGrams, type CalcOptions } from './calculator.ts';
import { overrideKey, resolveFood, type FoodDb } from './db.ts';
import { inflectAll } from './inflect.ts';
import { keyOf, normalizeBasic } from './text.ts';
import type { Dish, DishIngredient, Food, Macros, ParsedItem, UserOverride } from './types.ts';

export function slugify(s: string): string {
  return keyOf(s).replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 48) || 'pozycja';
}

/**
 * Skład pozycji jako jawna lista składników (rozmiar i mnożniki „wypieczone” w gramy),
 * np. do edycji składników albo zapisania jako własne danie.
 */
export function materialize(db: FoodDb, item: ParsedItem, opts: CalcOptions = {}): DishIngredient[] {
  const { components, scaleToGrams } = expandItem(db, item, opts);
  const out: DishIngredient[] = [];
  const grams: number[] = [];
  for (const c of components) {
    const rf = resolveFood(db, c.foodId);
    if (!rf) continue;
    const g = componentGrams(db, rf, c, opts).grams;
    grams.push(g);
    const simple = c.factors.length === 0 && (!c.size || c.size === 'standard') && c.unit !== null && scaleToGrams === null;
    const ing: DishIngredient = simple ? { foodId: c.foodId, qty: c.qty, unit: c.unit! } : { foodId: c.foodId, qty: Math.round(g), unit: 'g' };
    if (!simple && c.unit === null && c.factors.length === 0 && (!c.size || c.size === 'standard') && scaleToGrams === null && rf.defaultPortion)
      Object.assign(ing, { qty: c.qty, unit: rf.defaultPortion });
    if (c.optional) ing.optional = true;
    out.push(ing);
  }
  if (scaleToGrams !== null) {
    const total = grams.reduce((a, b) => a + b, 0) || 1;
    out.forEach((ing, i) => Object.assign(ing, { qty: Math.round((grams[i]! * scaleToGrams) / total), unit: 'g' }));
  }
  return out;
}

/** Czy fragment tekstu to po prostu nazwa/alias dania (wtedy nadpisujemy to danie). */
function fragmentNamesDish(dish: Dish, fragment: string): boolean {
  const k = keyOf(fragment);
  return [dish.name, ...(dish.aliases ?? []), ...(dish.forms ?? [])].some((n) => keyOf(n) === k);
}

export interface PersonalDefinition {
  override: UserOverride;
  /** Opis dla użytkownika, co się stanie. */
  description: string;
}

/**
 * „Zapamiętaj jako moje”:
 * - jeśli wpisano nazwę istniejącego dania → osobista wersja tego dania (nadpisanie),
 * - w przeciwnym razie → nowe danie użytkownika z aliasem równym wpisanemu fragmentowi.
 */
export function makePersonalDefinition(db: FoodDb, item: ParsedItem, opts: CalcOptions = {}, now = Date.now()): PersonalDefinition {
  const ingredients = materialize(db, { ...item, quantity: 1, unit: item.kind === 'dish' ? null : item.unit }, opts);
  const fragment = normalizeBasic(item.fragment || item.label || 'moje danie');
  const dish = item.kind === 'dish' ? db.dishes.get(item.matchedId) : undefined;
  // „bułka z szynką bez masła / z 3 plastrami szynki” = poprawka samego dania; wariant lub dodatek = nowe danie
  let core = fragment;
  for (const c of item.changes) if (c.op === 'remove' || c.op === 'set' || c.op === 'scale') core = core.replace(normalizeBasic(c.fragment), ' ');
  core = core.replace(/[,\s]+/g, ' ').trim();
  const structural = item.changes.some((c) => c.op === 'variant' || c.op === 'add');
  if (dish && !structural && fragmentNamesDish(dish, core)) {
    const data: Dish = { ...dish, ingredients };
    return {
      override: { key: overrideKey('dish', dish.id), kind: 'dish', id: dish.id, data, isNew: (db.origin.get(`dish:${dish.id}`) ?? 'default') === 'user', updatedAt: now },
      description: `Twoja wersja dania „${dish.name}”`,
    };
  }
  const id = `user-${slugify(fragment)}`;
  const existing = db.dishes.get(id);
  const data: Dish = {
    id,
    name: fragment,
    aliases: [],
    forms: inflectAll([fragment]).filter((f) => f !== fragment),
    ingredients,
    category: 'moje',
    source: 'definicja użytkownika',
    signature: false,
    ...(existing ? { aliases: existing.aliases } : {}),
  };
  return {
    override: { key: overrideKey('dish', id), kind: 'dish', id, data, isNew: true, updatedAt: now },
    description: `Nowe danie „${fragment}”`,
  };
}

/** Nowy produkt użytkownika z formami odmiany wygenerowanymi regułami. */
export function makeUserFood(input: { name: string; aliases?: string[]; per100: Macros; portions?: Record<string, number>; defaultPortion?: string; parentId?: string }, existingIds: Set<string>, now = Date.now()): UserOverride {
  const name = normalizeBasic(input.name);
  let id = `user-${slugify(name)}`;
  for (let i = 2; existingIds.has(id); i++) id = `user-${slugify(name)}-${i}`;
  const aliases = (input.aliases ?? []).map(normalizeBasic).filter(Boolean);
  const portions = input.portions && Object.keys(input.portions).length ? input.portions : { porcja: 100 };
  const food: Food = {
    id,
    name,
    per100: input.per100,
    portions,
    defaultPortion: input.defaultPortion && portions[input.defaultPortion] ? input.defaultPortion : Object.keys(portions)[0]!,
    aliases,
    forms: inflectAll([name, ...aliases]).filter((f) => f !== name && !aliases.includes(f)),
    category: 'moje',
    source: 'wartości wpisane przez użytkownika',
    verified: false,
  };
  if (input.parentId) food.parentId = input.parentId;
  return { key: overrideKey('food', id), kind: 'food', id, data: food, isNew: true, updatedAt: now };
}

/** Odświeżenie form po edycji nazwy/aliasów (zachowuje formy wpisane ręcznie w danych domyślnych). */
export function refreshForms<T extends { name: string; aliases?: string[]; forms?: string[] }>(x: T, keepForms: string[] = []): T {
  const base = [x.name, ...(x.aliases ?? [])].map(normalizeBasic);
  const forms = new Set([...inflectAll(base), ...keepForms]);
  for (const b of base) forms.delete(b);
  return { ...x, forms: [...forms].sort((a, b) => a.localeCompare(b, 'pl')) };
}
