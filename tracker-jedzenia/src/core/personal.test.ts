import { describe, expect, it } from 'vitest';
import { makePersonalDefinition, makeUserFood, materialize, slugify } from './personal.ts';
import { RuleParser } from './parser.ts';
import { computeItem } from './calculator.ts';
import { searchNames } from './search.ts';
import { buildLexicon } from './lexicon.ts';
import { testDb } from './testing.ts';

const db = testDb();
const parser = new RuleParser(db);

describe('osobiste definicje', () => {
  it('slugify', () => {
    expect(slugify('Duża bułka żytnia z szynką!')).toBe('duza-bulka-zytnia-z-szynka');
  });
  it('materialize zachowuje kcal pozycji', () => {
    const [it0] = parser.parse('duża bułka żytnia z szynką i pomidorem, bez masła').items;
    const ings = materialize(db, it0!);
    const asDish = computeItem(db, { ...it0!, kind: 'dish', ingredients: ings, changes: [], size: null });
    expect(asDish.totals.kcal).toBeCloseTo(computeItem(db, it0!).totals.kcal, 0);
    expect(ings.map((i) => i.foodId)).toEqual(['bulka-zytnia', 'szynka', 'pomidor']);
  });
  it('nazwa dania → osobista wersja tego dania; potem parser jej używa', () => {
    const [it0] = parser.parse('bułka z szynką bez masła').items;
    const edited = { ...it0!, ingredients: [{ foodId: 'bulka', qty: 1, unit: 'sztuka' }, { foodId: 'szynka', qty: 3, unit: 'plaster' }] };
    const def = makePersonalDefinition(db, edited);
    expect(def.override.id).toBe('bulka-z-szynka');
    expect(def.override.isNew).toBe(false);
    const udb = testDb([def.override]);
    const [again] = new RuleParser(udb).parse('bułka z szynką').items;
    expect(computeItem(udb, again!).lines.map((l) => [l.foodId, l.grams])).toEqual([['bulka', 60], ['szynka', 45]]);
  });
  it('inny opis → nowe danie z aliasem, które wygrywa przy tym samym tekście', () => {
    const [it0] = parser.parse('grahamka z serem i ogórkiem').items;
    const def = makePersonalDefinition(db, it0!);
    expect(def.override.isNew).toBe(true);
    expect(def.override.id).toBe('user-grahamka-z-serem-i-ogorkiem');
    const udb = testDb([def.override]);
    const r = new RuleParser(udb).parse('grahamkę z serem i ogórkiem');
    expect(r.items.map((i) => i.matchedId)).toEqual(['user-grahamka-z-serem-i-ogorkiem']);
    // nie przejmuje innych opisów przez sygnaturę
    expect(new RuleParser(udb).parse('bułka z serem').items[0]!.matchedId).toBe('bulka-z-serem');
  });
  it('nowy produkt użytkownika jest rozpoznawany w odmianie', () => {
    const o = makeUserFood({ name: 'kiełbasa myśliwska', per100: { kcal: 300, carbs: 1, protein: 20, fat: 24 }, portions: { plaster: 10 } }, new Set(db.foods.keys()));
    const udb = testDb([o]);
    const r = new RuleParser(udb).parse('3 plastry kiełbasy myśliwskiej');
    expect(r.items[0]).toMatchObject({ matchedId: o.id, quantity: 3, unit: 'plaster' });
  });
  it('wyszukiwanie podpowiedzi', () => {
    const lex = buildLexicon(db);
    expect(searchNames(db, lex, 'bułka ż')[0]!.id).toBe('bulka-zytnia');
    expect(searchNames(db, lex, 'szynk').map((s) => s.id)).toContain('szynka');
    expect(searchNames(db, lex, 'jgurt', 8, ['food']).map((s) => s.id)).toContain('jogurt-naturalny');
  });
});
