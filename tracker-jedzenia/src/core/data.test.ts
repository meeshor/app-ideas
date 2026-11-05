import { describe, expect, it } from 'vitest';
import { DEFAULT_DATA } from './defaults.ts';
import { buildLexicon } from './lexicon.ts';
import { resolveFood } from './db.ts';
import { testDb } from './testing.ts';

const db = testDb();
const units = DEFAULT_DATA.modifiers.units;

describe('dane startowe', () => {
  it('mają co najmniej ~150 produktów i ~40 dań', () => {
    expect(DEFAULT_DATA.foods.length).toBeGreaterThanOrEqual(150);
    expect(DEFAULT_DATA.dishes.length).toBeGreaterThanOrEqual(40);
  });
  it('id są unikalne', () => {
    const ids = DEFAULT_DATA.foods.map((f) => f.id);
    expect(new Set(ids).size).toBe(ids.length);
    const dids = DEFAULT_DATA.dishes.map((d) => d.id);
    expect(new Set(dids).size).toBe(dids.length);
  });
  it('każdy produkt ma (własne lub odziedziczone) makro, porcję domyślną i źródło', () => {
    for (const f of DEFAULT_DATA.foods) {
      const rf = resolveFood(db, f.id)!;
      expect(rf, f.id).toBeTruthy();
      expect(f.source, f.id).toBeTruthy();
      expect(f.verified, f.id).toBe(false);
      const m = rf.per100;
      for (const v of [m.kcal, m.carbs, m.protein, m.fat]) expect(v, f.id).toBeGreaterThanOrEqual(0);
      expect(m.carbs + m.protein + m.fat, f.id).toBeLessThanOrEqual(100.5);
      // spójność energii: 4/4/9 ± tolerancja (alkohol i błonnik psują bilans — pomijamy alkohole)
      if (!['wodka', 'wino', 'piwo', 'piwo-bezalkoholowe'].includes(f.id) && m.kcal > 50) {
        const atwater = 4 * m.carbs + 4 * m.protein + 9 * m.fat;
        expect(Math.abs(atwater - m.kcal) / m.kcal, `${f.id}: ${atwater} vs ${m.kcal}`).toBeLessThan(0.25);
      }
      expect(rf.defaultPortion, f.id).toBeTruthy();
      expect(rf.portions[rf.defaultPortion!], f.id).toBeGreaterThan(0);
    }
  });
  it('warianty wskazują istniejącego rodzica', () => {
    for (const f of DEFAULT_DATA.foods.filter((x) => x.parentId)) expect(db.foods.has(f.parentId!), f.id).toBe(true);
  });
  it('porcje, dodatki i składniki dań używają znanych jednostek i produktów', () => {
    for (const f of DEFAULT_DATA.foods) {
      for (const u of Object.keys(f.portions ?? {})) expect(units[u], `${f.id}.${u}`).toBeTruthy();
      if (f.addon) expect(units[f.addon.unit], `${f.id} addon`).toBeTruthy();
      if (f.sizes) expect(f.sizes.small! <= f.sizes.standard! && f.sizes.standard! <= f.sizes.large!, f.id).toBe(true);
    }
    for (const d of DEFAULT_DATA.dishes) {
      expect(d.ingredients.length, d.id).toBeGreaterThan(0);
      for (const i of d.ingredients) {
        expect(db.foods.has(i.foodId), `${d.id} → ${i.foodId}`).toBe(true);
        expect(units[i.unit], `${d.id} → ${i.unit}`).toBeTruthy();
      }
    }
  });
  it('nazwy bazowe i aliasy nie kolidują między różnymi produktami', () => {
    const lex = buildLexicon(db);
    const owners = new Map<string, Set<string>>();
    for (const list of lex.names.values())
      for (const e of list) {
        if (!e.isBase) continue;
        const k = e.keys.join(' ');
        owners.set(k, (owners.get(k) ?? new Set()).add(`${e.kind}:${e.id}`));
      }
    const conflicts = [...owners].filter(([, s]) => s.size > 1).map(([k, s]) => `${k}: ${[...s].join(', ')}`);
    expect(conflicts).toEqual([]);
  });
  it('nazwy bazowe nie są słowami funkcyjnymi (jednostki, liczebniki, modyfikatory)', () => {
    const lex = buildLexicon(db);
    // „pączek” ≈ „paczek” (dopełniacz od „paczka”) — rozstrzygane po polskich znakach (parser.unitAt)
    const allowed = new Set(['paczek: paczek']);
    const bad: string[] = [];
    for (const list of lex.names.values())
      for (const e of list) if (e.isBase && e.keys.length === 1 && lex.functionWords.has(e.keys[0]!) && !allowed.has(`${e.id}: ${e.keys[0]}`)) bad.push(`${e.id}: ${e.keys[0]}`);
    expect(bad).toEqual([]);
  });
});
