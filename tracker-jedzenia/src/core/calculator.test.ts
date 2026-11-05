import { describe, expect, it } from 'vitest';
import { computeItem, roundMacros } from './calculator.ts';
import { testDb } from './testing.ts';
import type { ParsedItem } from './types.ts';

const db = testDb();
const item = (p: Partial<ParsedItem> & Pick<ParsedItem, 'kind' | 'matchedId'>): ParsedItem => ({
  quantity: 1, unit: null, size: null, modifiers: [], factor: 1, confidence: 1, fragment: '', changes: [], ...p,
});

describe('kalkulator', () => {
  it('produkt w gramach', () => {
    const c = computeItem(db, item({ kind: 'food', matchedId: 'maslo', quantity: 5, unit: 'g' }));
    expect(c.grams).toBe(5);
    expect(Math.round(c.totals.kcal)).toBe(37);
    expect(c.lines[0]!.explain).toBe('masło 5 g → 37 kcal');
  });
  it('porcja nazwana i forma liczebnikowa', () => {
    const c = computeItem(db, item({ kind: 'food', matchedId: 'szynka', quantity: 2, unit: 'plaster' }));
    expect(c.grams).toBe(30);
    expect(c.lines[0]!.explain).toMatch(/^szynka 2 plastry = 30 g → \d+ kcal$/);
  });
  it('rozmiar: gramy klasy z produktu mają pierwszeństwo', () => {
    const c = computeItem(db, item({ kind: 'food', matchedId: 'bulka', size: 'large' }));
    expect(c.grams).toBe(80);
    expect(c.lines[0]!.explain).toContain('(duża: 80 g)');
  });
  it('rozmiar: mnożnik globalny, gdy produkt nie ma gramów klasy', () => {
    const c = computeItem(db, item({ kind: 'food', matchedId: 'bulka', size: 'huge' }));
    expect(c.grams).toBeCloseTo(90);
    expect(c.lines[0]!.explain).toContain('× 1,5 (ogromna)');
    expect(c.confidence).toBeLessThan(1);
  });
  it('rozmiar: mnożnik z ustawień nadpisuje domyślny', () => {
    const c = computeItem(db, item({ kind: 'food', matchedId: 'bulka', size: 'huge' }), { sizeMultipliers: { huge: 2 } });
    expect(c.grams).toBeCloseTo(120);
  });
  it('wariant dziedziczy masę porcji po rodzicu, ale ma własne makro', () => {
    const p = computeItem(db, item({ kind: 'food', matchedId: 'bulka' }));
    const v = computeItem(db, item({ kind: 'food', matchedId: 'bulka-zytnia' }));
    expect(v.grams).toBe(p.grams);
    expect(v.totals.kcal).toBeLessThan(p.totals.kcal);
  });
  it('ml przeliczane gęstością', () => {
    const c = computeItem(db, item({ kind: 'food', matchedId: 'mleko', quantity: 100, unit: 'ml' }));
    expect(c.grams).toBeCloseTo(103);
  });
  it('jednostka zapasowa obniża pewność', () => {
    const c = computeItem(db, item({ kind: 'food', matchedId: 'banan', quantity: 1, unit: 'talerz' }));
    expect(c.grams).toBe(300);
    expect(c.confidence).toBeLessThan(1);
  });
  it('danie: skład domyślny, wariant, „bez”, dodatek, ilość porcji', () => {
    const base = computeItem(db, item({ kind: 'dish', matchedId: 'bulka-z-szynka' }));
    expect(base.lines.map((l) => l.foodId)).toEqual(['bulka', 'szynka', 'maslo']);
    expect(roundMacros(base.totals).kcal).toBeGreaterThan(200);
    const mod = computeItem(db, item({
      kind: 'dish', matchedId: 'bulka-z-szynka', quantity: 2,
      changes: [
        { op: 'variant', foodId: 'bulka-zytnia', fragment: '' },
        { op: 'remove', foodId: 'maslo', fragment: 'bez masła' },
        { op: 'add', foodId: 'ser-zolty', qty: 1, unit: 'plaster', fragment: 'z serem' },
      ],
    }));
    expect(mod.lines.map((l) => l.foodId)).toEqual(['bulka-zytnia', 'szynka', 'ser-zolty']);
    expect(mod.removed).toEqual(['masło']);
    expect(mod.lines[0]!.grams).toBe(120);
    expect(mod.lines[2]!.grams).toBe(40);
  });
  it('danie skalowane do gramów („300 g bigosu”)', () => {
    const c = computeItem(db, item({ kind: 'dish', matchedId: 'pomidorowa-z-makaronem', quantity: 500, unit: 'g' }));
    expect(c.grams).toBeCloseTo(500);
  });
  it('danie z rozmiarem „all” skaluje wszystko', () => {
    const c = computeItem(db, item({ kind: 'dish', matchedId: 'pomidorowa-z-makaronem', size: 'large' }));
    expect(c.grams).toBeCloseTo(360 * 1.2);
  });
  it('jawna lista składników (po edycji) zastępuje skład dania', () => {
    const c = computeItem(db, item({ kind: 'dish', matchedId: 'bulka-z-szynka', ingredients: [{ foodId: 'bulka', qty: 1, unit: 'sztuka' }, { foodId: 'szynka', qty: 3, unit: 'plaster' }] }));
    expect(c.lines.map((l) => l.grams)).toEqual([60, 45]);
  });
  it('jest deterministyczny', () => {
    const it1 = item({ kind: 'dish', matchedId: 'bulka-z-szynka', size: 'huge' });
    expect(computeItem(db, it1)).toEqual(computeItem(db, it1));
  });
});
