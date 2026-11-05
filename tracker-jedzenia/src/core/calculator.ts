// Kalkulator: pozycja z parsera → składniki → gramy → makro, z czytelnym rozbiciem.
// Kolejność rozstrzygania rozmiaru: gramy klasy rozmiaru z produktu → mnożnik globalny (ustawienia / modifiers.json).

import { CONFIG } from './config.ts';
import { resolveFood, sameFamily, type FoodDb, type ResolvedFood } from './db.ts';
import { fmtNum, plural } from './format.ts';
import type { BreakdownLine, ComputedItem, DishIngredient, Macros, ParsedItem, SizeKey, UnitKey } from './types.ts';

export interface Component {
  foodId: string;
  qty: number;
  unit: UnitKey | null;
  size: SizeKey | null;
  /** Mnożniki z opisem do rozbicia, np. [{ value: 2, label: 'dużo' }]. */
  factors: { value: number; label: string }[];
  optional?: boolean;
}

export interface CalcOptions {
  /** Mnożniki rozmiaru z ustawień (nadpisują modifiers.json). */
  sizeMultipliers?: Partial<Record<SizeKey, number>>;
}

export const ZERO_MACROS: Macros = { kcal: 0, carbs: 0, protein: 0, fat: 0 };

export function addMacros(a: Macros, b: Macros): Macros {
  return { kcal: a.kcal + b.kcal, carbs: a.carbs + b.carbs, protein: a.protein + b.protein, fat: a.fat + b.fat };
}

export function scaleMacros(m: Macros, k: number): Macros {
  return { kcal: m.kcal * k, carbs: m.carbs * k, protein: m.protein * k, fat: m.fat * k };
}

export function roundMacros(m: Macros): Macros {
  const r = (x: number) => Math.round(x * 10) / 10;
  return { kcal: Math.round(m.kcal), carbs: r(m.carbs), protein: r(m.protein), fat: r(m.fat) };
}

export function sumMacros(list: readonly Macros[]): Macros {
  return list.reduce(addMacros, ZERO_MACROS);
}

/** Etykieta mnożnika ilości („dużo”, „mało”) wg modifiers.json. */
export function amountLabel(db: FoodDb, factor: number): string {
  return db.modifiers.amounts.find((a) => a.multiplier === factor)?.label ?? 'mnożnik';
}

export function sizeMultiplier(db: FoodDb, size: SizeKey, opts: CalcOptions = {}): number {
  return opts.sizeMultipliers?.[size] ?? db.modifiers.sizes[size]?.multiplier ?? 1;
}

function isMassOrVolume(db: FoodDb, unit: UnitKey | null): boolean {
  if (!unit) return false;
  const u = db.modifiers.units[unit];
  return !!u && (u.grams !== undefined || (u.ml !== undefined && (unit === 'ml' || unit === 'l')));
}

/** Rozwija pozycję do listy składników (dla produktu: on sam + dodatki; dla dania: skład po zmianach). */
export function expandItem(db: FoodDb, item: ParsedItem, opts: CalcOptions = {}): { components: Component[]; removed: string[]; scaleToGrams: number | null } {
  const removed: string[] = [];
  const comps: Component[] = [];
  let mainIdx = 0;
  let scaleToGrams: number | null = null;
  const sizeLabel = (s: SizeKey) => db.modifiers.sizes[s]?.label ?? s;

  if (item.kind === 'food') {
    const f: Component = { foodId: item.matchedId, qty: item.quantity, unit: item.unit, size: item.size, factors: [] };
    if (item.factor !== 1) f.factors.push({ value: item.factor, label: amountLabel(db, item.factor) });
    comps.push(f);
  } else {
    const dish = db.dishes.get(item.matchedId);
    const base: DishIngredient[] = item.ingredients ?? dish?.ingredients ?? [];
    mainIdx = Math.min(dish?.main ?? 0, Math.max(0, base.length - 1));
    for (const ing of base) {
      const c: Component = { foodId: ing.foodId, qty: ing.qty, unit: ing.unit, size: null, factors: [] };
      if (ing.optional) c.optional = true;
      comps.push(c);
    }
  }

  // Zmiany z parsera (nie stosujemy ich ponownie, gdy użytkownik zapisał jawny skład)
  const changes = item.kind === 'dish' && item.ingredients ? item.changes.filter((c) => c.op === 'add') : item.changes;
  const findComp = (foodId: string, preferMain: boolean) => {
    if (preferMain && comps[mainIdx] && sameFamily(db, comps[mainIdx]!.foodId, foodId)) return comps[mainIdx];
    return comps.find((c) => sameFamily(db, c.foodId, foodId));
  };
  for (const ch of changes) {
    switch (ch.op) {
      case 'variant': {
        const c = findComp(ch.foodId, true);
        if (c) c.foodId = ch.foodId;
        break;
      }
      case 'set': {
        const c = findComp(ch.foodId, false);
        if (c) {
          c.qty = ch.qty;
          c.unit = ch.unit ?? (isMassOrVolume(db, c.unit) ? null : c.unit);
          c.foodId = ch.foodId;
        }
        break;
      }
      case 'scale': {
        const c = findComp(ch.foodId, false);
        if (c) c.factors.push({ value: ch.factor, label: amountLabel(db, ch.factor) });
        break;
      }
      case 'remove': {
        const idx = comps.findIndex((c) => sameFamily(db, c.foodId, ch.foodId));
        if (idx >= 0) {
          removed.push(db.foods.get(comps[idx]!.foodId)?.name ?? ch.foodId);
          comps.splice(idx, 1);
          if (idx < mainIdx) mainIdx--;
        }
        break;
      }
      case 'add': {
        const c: Component = { foodId: ch.foodId, qty: ch.qty, unit: ch.unit, size: ch.size ?? null, factors: [] };
        if (ch.factor && ch.factor !== 1) c.factors.push({ value: ch.factor, label: amountLabel(db, ch.factor) });
        comps.push(c);
        break;
      }
    }
  }

  if (item.kind === 'dish') {
    const dish = db.dishes.get(item.matchedId);
    if (item.size && item.size !== 'standard') {
      if ((dish?.sizeMode ?? 'main') === 'all') {
        const m = sizeMultiplier(db, item.size, opts);
        for (const c of comps) c.factors.push({ value: m, label: sizeLabel(item.size) });
      } else if (comps[mainIdx]) comps[mainIdx]!.size = item.size;
    }
    if (isMassOrVolume(db, item.unit)) {
      const u = db.modifiers.units[item.unit!]!;
      scaleToGrams = item.quantity * (u.grams ?? u.ml ?? 1);
    } else if (item.quantity !== 1) {
      for (const c of comps) c.qty *= item.quantity;
    }
    if (item.factor !== 1) for (const c of comps) c.factors.push({ value: item.factor, label: amountLabel(db, item.factor) });
  }
  return { components: comps, removed, scaleToGrams };
}

interface GramsResult {
  grams: number;
  /** Opis ilości przed „=”, np. „2 plastry”, „60 g × 1,2 (duża)”. */
  qtyText: string;
  approximate: boolean;
  approxSize: boolean;
}

/** Gramy składnika wraz z opisem, skąd się wzięły. */
export function componentGrams(db: FoodDb, rf: ResolvedFood, c: Component, opts: CalcOptions = {}): GramsResult {
  const units = db.modifiers.units;
  let unit = c.unit;
  let approximate = false;
  let approxSize = false;
  const factors = [...c.factors];
  let per: number;
  let qtyText: string;
  const unitDef = unit ? units[unit] : undefined;

  if (unit && unitDef?.grams !== undefined) {
    per = unitDef.grams;
    qtyText = `${fmtNum(c.qty * per)} g`;
  } else if (unit && (unit === 'ml' || unit === 'l')) {
    per = (unitDef?.ml ?? 1) * rf.density;
    qtyText = `${fmtNum(c.qty * (unitDef?.ml ?? 1))} ml`;
  } else {
    // porcja nazwana
    if (!unit || ((unit === 'sztuka' || unit === 'porcja') && rf.portions[unit] === undefined)) unit = rf.defaultPortion;
    const isDefault = unit === rf.defaultPortion;
    if (unit && rf.portions[unit] !== undefined) per = rf.portions[unit]!;
    else if (unit && units[unit]?.ml !== undefined) {
      per = units[unit]!.ml! * rf.density;
      approximate = true;
    } else if (unit && units[unit]?.fallbackGrams !== undefined) {
      per = units[unit]!.fallbackGrams!;
      approximate = true;
    } else {
      per = CONFIG.calculator.defaultPortionGrams;
      approximate = true;
    }
    const def = unit ? units[unit] : undefined;
    const label = def ? plural(c.qty, def.label, def.plural ?? def.label, def.genitivePlural ?? def.plural ?? def.label) : 'porcja';
    let sizeText = '';
    if (c.size && c.size !== 'standard') {
      const s = c.size;
      const sized = isDefault && s !== 'huge' ? rf.sizes[s] : undefined;
      const sLabel = db.modifiers.sizes[s]?.label ?? s;
      if (sized !== undefined) {
        sizeText = ` (${sLabel}: ${fmtNum(sized)} g)`;
        per = sized;
      } else {
        const m = sizeMultiplier(db, s, opts);
        factors.unshift({ value: m, label: sLabel });
        approxSize = true;
      }
    }
    qtyText = c.qty === 1 && (unit === 'sztuka' || !unit) && !sizeText ? `${fmtNum(per)} g` : `${fmtNum(c.qty, 2)} ${label}${sizeText}`;
  }
  let grams = c.qty * per;
  for (const f of factors) {
    grams *= f.value;
    qtyText += ` × ${fmtNum(f.value, 2)}${f.label ? ` (${f.label})` : ''}`;
  }
  return { grams, qtyText, approximate, approxSize };
}

export function computeItem(db: FoodDb, item: ParsedItem, opts: CalcOptions = {}): ComputedItem {
  const { components, removed, scaleToGrams } = expandItem(db, item, opts);
  const lines: BreakdownLine[] = [];
  let confidence = item.confidence;
  const raw: { c: Component; rf: ResolvedFood; g: GramsResult }[] = [];
  for (const c of components) {
    const rf = resolveFood(db, c.foodId);
    if (!rf) continue;
    const g = componentGrams(db, rf, c, opts);
    if (g.approximate) confidence *= CONFIG.parser.confidence.fallbackUnit;
    if (g.approxSize) confidence *= CONFIG.parser.confidence.fallbackSize;
    raw.push({ c, rf, g });
  }
  if (scaleToGrams !== null) {
    const total = raw.reduce((s, r) => s + r.g.grams, 0);
    if (total > 0) {
      const k = scaleToGrams / total;
      for (const r of raw) {
        r.g.grams *= k;
        r.g.qtyText += ` × ${fmtNum(k, 2)} (do ${fmtNum(scaleToGrams)} g)`;
      }
    }
  }
  for (const { rf, g } of raw) {
    const macros = scaleMacros(rf.per100, g.grams / 100);
    const shown = g.qtyText;
    const gramsText = `${fmtNum(g.grams)} g`;
    const explain = shown === gramsText ? `${rf.name} ${gramsText} → ${Math.round(macros.kcal)} kcal` : `${rf.name} ${shown} = ${gramsText} → ${Math.round(macros.kcal)} kcal`;
    lines.push({ foodId: rf.id, foodName: rf.name, grams: g.grams, macros, explain, approximate: g.approximate || g.approxSize });
  }
  const totals = sumMacros(lines.map((l) => l.macros));
  return {
    label: itemLabel(db, item),
    lines,
    removed,
    totals,
    grams: lines.reduce((s, l) => s + l.grams, 0),
    confidence: Math.round(confidence * 100) / 100,
  };
}

export function itemLabel(db: FoodDb, item: ParsedItem): string {
  const base = item.kind === 'food' ? db.foods.get(item.matchedId)?.name : db.dishes.get(item.matchedId)?.name;
  const variants = item.changes.filter((c) => c.op === 'variant').map((c) => db.foods.get(c.foodId)?.name ?? c.foodId);
  let label = base ?? item.matchedId;
  if (variants.length) label += ` (${variants.join(', ')})`;
  return label;
}

export function computeAll(db: FoodDb, items: readonly ParsedItem[], opts: CalcOptions = {}): { computed: ComputedItem[]; totals: Macros } {
  const computed = items.map((i) => computeItem(db, i, opts));
  return { computed, totals: sumMacros(computed.map((c) => c.totals)) };
}
