// Baza w pamięci: dane domyślne + nakładka UserOverride. Dziedziczenie wariantów.

import type { Dish, Food, Macros, ModifiersData, SizeKey, UserOverride } from './types.ts';
import { CONFIG } from './config.ts';

export interface FoodDb {
  foods: Map<string, Food>;
  dishes: Map<string, Dish>;
  modifiers: ModifiersData;
  /** Skąd pochodzi rekord: domyślny, zmieniony przez użytkownika, dodany przez użytkownika. */
  origin: Map<string, 'default' | 'changed' | 'user'>;
}

export interface DefaultData {
  foods: Food[];
  dishes: Dish[];
  modifiers: ModifiersData;
}

export function overrideKey(kind: UserOverride['kind'], id: string): string {
  return `${kind}:${id}`;
}

/** Scala dane domyślne z nadpisaniami użytkownika (nadpisanie zastępuje cały rekord). */
export function buildDb(defaults: DefaultData, overrides: readonly UserOverride[] = []): FoodDb {
  const foods = new Map(defaults.foods.map((f) => [f.id, f]));
  const dishes = new Map(defaults.dishes.map((d) => [d.id, d]));
  const origin = new Map<string, 'default' | 'changed' | 'user'>();
  let modifiers = defaults.modifiers;
  for (const o of overrides) {
    if (o.kind === 'modifiers') {
      if (o.data) modifiers = o.data as ModifiersData;
      continue;
    }
    const map = (o.kind === 'food' ? foods : dishes) as Map<string, Food | Dish>;
    if (o.data === null) map.delete(o.id);
    else map.set(o.id, o.data as Food | Dish);
    origin.set(overrideKey(o.kind, o.id), o.isNew ? 'user' : 'changed');
  }
  return { foods, dishes, modifiers, origin };
}

/** Łańcuch: produkt, rodzic, dziadek… (ochrona przed cyklem). */
export function ancestry(db: FoodDb, id: string): Food[] {
  const chain: Food[] = [];
  const seen = new Set<string>();
  let cur = db.foods.get(id);
  while (cur && !seen.has(cur.id)) {
    chain.push(cur);
    seen.add(cur.id);
    cur = cur.parentId ? db.foods.get(cur.parentId) : undefined;
  }
  return chain;
}

/** Id produktu najwyższego w rodzinie (bez rodzica). */
export function rootId(db: FoodDb, id: string): string {
  const chain = ancestry(db, id);
  return chain.length ? chain[chain.length - 1]!.id : id;
}

/** Czy dwa produkty należą do tej samej rodziny (wariant ↔ produkt bazowy). */
export function sameFamily(db: FoodDb, a: string, b: string): boolean {
  return a === b || rootId(db, a) === rootId(db, b);
}

export interface ResolvedFood {
  id: string;
  name: string;
  per100: Macros;
  portions: Record<string, number>;
  defaultPortion: string | null;
  sizes: Partial<Record<Exclude<SizeKey, 'huge'>, number>>;
  addon: { qty: number; unit: string } | null;
  density: number;
  isVariant: boolean;
}

const ZERO: Macros = { kcal: 0, carbs: 0, protein: 0, fat: 0 };

/** Produkt z odziedziczonymi polami (pola wariantu mają pierwszeństwo; porcje i rozmiary scalane). */
export function resolveFood(db: FoodDb, id: string): ResolvedFood | null {
  const chain = ancestry(db, id);
  if (chain.length === 0) return null;
  const top = chain[0]!;
  const pick = <K extends keyof Food>(k: K): Food[K] | undefined => {
    for (const f of chain) if (f[k] !== undefined) return f[k];
    return undefined;
  };
  const portions: Record<string, number> = {};
  const sizes: Partial<Record<Exclude<SizeKey, 'huge'>, number>> = {};
  for (const f of [...chain].reverse()) {
    Object.assign(portions, f.portions ?? {});
    Object.assign(sizes, f.sizes ?? {});
  }
  const defaultPortion = pick('defaultPortion') ?? Object.keys(portions)[0] ?? null;
  return {
    id: top.id,
    name: top.name,
    per100: pick('per100') ?? ZERO,
    portions,
    defaultPortion,
    sizes,
    addon: pick('addon') ?? null,
    density: pick('density') ?? CONFIG.calculator.defaultDensity,
    isVariant: chain.length > 1,
  };
}

export function displayName(db: FoodDb, kind: 'food' | 'dish', id: string): string {
  return (kind === 'food' ? db.foods.get(id)?.name : db.dishes.get(id)?.name) ?? id;
}
