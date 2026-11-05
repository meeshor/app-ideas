// Zestaw przypadków parsera: tabela wejście → oczekiwany wynik.
// Skrót oczekiwań: `id` = matchedId; `ch` = zmiany w postaci „op:foodId” (np. 'variant:bulka-zytnia').
// `conf: 'lt1'` = pewność < 1 (bez polskich znaków / literówka).

import { describe, expect, it } from 'vitest';
import { RuleParser } from './parser.ts';
import { computeItem } from './calculator.ts';
import { testDb } from './testing.ts';
import type { Dish, ParsedItem, SizeKey } from './types.ts';

interface Exp {
  id: string;
  kind?: 'food' | 'dish';
  qty?: number;
  unit?: string | null;
  size?: SizeKey | null;
  ch?: string[];
  factor?: number;
  conf?: 'lt1' | 1;
}
interface Case {
  in: string;
  items: Exp[];
  unknown?: string[];
  meal?: string;
  note?: string;
}

const CASES: Case[] = [
  // --- podstawy i odmiana ---
  { in: 'bułka', items: [{ id: 'bulka', kind: 'food', qty: 1, unit: null, conf: 1 }] },
  { in: 'bułkę', items: [{ id: 'bulka', qty: 1 }] },
  { in: 'kajzerka', items: [{ id: 'bulka' }] },
  { in: 'zjadłem bułkę', items: [{ id: 'bulka' }] },
  { in: 'jajko', items: [{ id: 'jajko', qty: 1 }] },
  { in: 'jabłko', items: [{ id: 'jablko' }] },
  { in: 'banana', items: [{ id: 'banan' }] },
  { in: 'twarożek', items: [{ id: 'twarog' }] },
  { in: 'ser biały', items: [{ id: 'twarog' }], note: 'alias wielowyrazowy wygrywa z „ser”' },
  { in: 'biały ser', items: [{ id: 'twarog' }], note: 'szyk odwrotny' },
  { in: 'ziemniaki', items: [{ id: 'ziemniaki' }] },
  { in: 'kotlet schabowy', items: [{ id: 'kotlet-schabowy' }] },
  { in: 'schabowego', items: [{ id: 'kotlet-schabowy' }] },
  { in: 'pierogi ruskie', items: [{ id: 'pierogi' }] },
  { in: 'pierogi z mięsem', items: [{ id: 'pierogi-z-miesem', kind: 'food' }], note: 'nazwa z „z” jako alias produktu' },
  { in: 'pierogi z kapustą i grzybami', items: [{ id: 'pierogi-z-kapusta' }], note: 'alias zawierający „i”' },
  { in: 'pierś z kurczaka', items: [{ id: 'kurczak' }] },
  { in: 'talerz pomidorowej', items: [{ id: 'zupa-pomidorowa', unit: 'talerz' }] },
  // --- liczebniki i ilości ---
  { in: '2 jajka', items: [{ id: 'jajko', qty: 2 }] },
  { in: 'dwa jajka', items: [{ id: 'jajko', qty: 2 }] },
  { in: 'trzy jajka', items: [{ id: 'jajko', qty: 3 }] },
  { in: 'pięć pierogów', items: [{ id: 'pierogi', qty: 5 }] },
  { in: 'pół bułki', items: [{ id: 'bulka', qty: 0.5 }] },
  { in: 'półtorej bułki', items: [{ id: 'bulka', qty: 1.5 }] },
  { in: '2 i pół bułki', items: [{ id: 'bulka', qty: 2.5 }] },
  { in: '1/2 tabliczki czekolady', items: [{ id: 'czekolada', qty: 0.5, unit: 'tabliczka' }] },
  { in: '2,5 kromki chleba', items: [{ id: 'chleb', qty: 2.5, unit: 'kromka' }] },
  { in: '200 g ryżu', items: [{ id: 'ryz', qty: 200, unit: 'g' }] },
  { in: '200g ryżu', items: [{ id: 'ryz', qty: 200, unit: 'g' }] },
  { in: 'ryż 150 g', items: [{ id: 'ryz', qty: 150, unit: 'g' }], note: 'ilość po nazwie' },
  { in: 'szklanka mleka', items: [{ id: 'mleko', qty: 1, unit: 'szklanka' }] },
  { in: 'pół szklanki mleka', items: [{ id: 'mleko', qty: 0.5, unit: 'szklanka' }] },
  { in: 'dwie łyżki cukru', items: [{ id: 'cukier', qty: 2, unit: 'lyzka' }] },
  { in: '3 plastry szynki', items: [{ id: 'szynka', qty: 3, unit: 'plaster' }] },
  { in: 'kawałek pizzy', items: [{ id: 'pizza', qty: 1, unit: 'kawalek' }] },
  { in: 'garść orzechów', items: [{ id: 'orzechy-wloskie', unit: 'garsc' }] },
  { in: 'piwo 0,5 l', items: [{ id: 'piwo', qty: 0.5, unit: 'l' }] },
  { in: '250 ml kefiru', items: [{ id: 'kefir', qty: 250, unit: 'ml' }] },
  { in: 'bułka x2', items: [{ id: 'bulka', qty: 2 }] },
  { in: '100 g twarogu chudego', items: [{ id: 'twarog-chudy', qty: 100, unit: 'g' }] },
  { in: 'jogurt naturalny 2 łyżki', items: [{ id: 'jogurt-naturalny', qty: 2, unit: 'lyzka' }] },
  { in: 'trochę ryżu', items: [{ id: 'ryz', factor: 0.5 }] },
  { in: 'cała pizza', items: [{ id: 'pizza', unit: 'sztuka' }] },
  { in: '2 pączki', items: [{ id: 'paczek', qty: 2 }], note: '„pączki” ≠ jednostka „paczki”' },
  { in: 'paczka chipsów', items: [{ id: 'chipsy', unit: 'opakowanie' }] },
  // --- rozmiary i modyfikatory ilości ---
  { in: 'duża bułka', items: [{ id: 'bulka', size: 'large' }] },
  { in: 'bułka duża', items: [{ id: 'bulka', size: 'large' }], note: 'rozmiar po nazwie' },
  { in: 'mała kawa', items: [{ id: 'kawa', size: 'small' }] },
  { in: 'ogromna pizza', items: [{ id: 'pizza', size: 'huge' }] },
  { in: '2 duże jajka', items: [{ id: 'jajko', qty: 2, size: 'large' }] },
  { in: 'dużo frytek', items: [{ id: 'frytki', factor: 2 }] },
  // --- warianty ---
  { in: 'bułka żytnia', items: [{ id: 'bulka-zytnia' }] },
  { in: 'żytnia bułka', items: [{ id: 'bulka-zytnia' }] },
  { in: 'grahamka', items: [{ id: 'bulka-grahamka' }] },
  { in: 'chleb razowy', items: [{ id: 'chleb-razowy' }] },
  { in: 'mleko owsiane', items: [{ id: 'mleko-owsiane' }] },
  // --- dania i sygnatury ---
  { in: 'bułka z szynką', items: [{ id: 'bulka-z-szynka', kind: 'dish', ch: [] }] },
  { in: 'bułkę z szynką', items: [{ id: 'bulka-z-szynka' }] },
  { in: 'duża bułka żytnia z szynką', items: [{ id: 'bulka-z-szynka', size: 'large', ch: ['variant:bulka-zytnia'] }] },
  { in: 'bułka żytnia z szynką i serem', items: [{ id: 'bulka-z-szynka-i-serem', ch: ['variant:bulka-zytnia'] }], note: 'sygnatura z dwoma dodatkami' },
  { in: 'duża bułka żytnia z szynką i serem', items: [{ id: 'bulka-z-szynka-i-serem', size: 'large', ch: ['variant:bulka-zytnia'] }] },
  { in: '2 bułki z szynką', items: [{ id: 'bulka-z-szynka', qty: 2 }] },
  { in: 'bułka z szynką drobiową', items: [{ id: 'bulka-z-szynka', ch: ['variant:szynka-drobiowa'] }], note: 'wariant dodatku' },
  { in: 'bułka z szynką i pomidorem', items: [{ id: 'bulka-z-szynka', ch: ['add:pomidor'] }], note: 'dopisek bez osobnego dania' },
  { in: 'bułka z 3 plastrami szynki', items: [{ id: 'bulka-z-szynka', ch: ['set:szynka'] }] },
  { in: 'kanapka z serem', items: [{ id: 'kanapka', kind: 'dish', ch: ['add:ser-zolty'] }], note: 'danie jako baza + dodatek' },
  { in: 'kawa z mlekiem', items: [{ id: 'kawa-z-mlekiem' }] },
  { in: 'kawa z mlekiem i cukrem', items: [{ id: 'kawa-z-mlekiem-i-cukrem' }] },
  { in: 'kawa z cukrem', items: [{ id: 'kawa', kind: 'food', ch: ['add:cukier'] }] },
  { in: 'owsianka z bananem', items: [{ id: 'owsianka', ch: ['add:banan'] }] },
  { in: 'płatki owsiane z mlekiem', items: [{ id: 'owsianka' }], note: 'sygnatura: płatki owsiane + mleko' },
  { in: 'jajecznica z 4 jajek', items: [{ id: 'jajecznica', ch: ['set:jajko'] }] },
  { in: 'jajecznica na boczku', items: [{ id: 'jajecznica-na-boczku' }] },
  { in: 'pomidorowa z makaronem', items: [{ id: 'pomidorowa-z-makaronem' }] },
  { in: 'schabowy z ziemniakami i surówką', items: [{ id: 'schabowy-z-ziemniakami', ch: ['add:surowka'] }] },
  { in: 'kurczak z ryżem i brokułami', items: [{ id: 'kurczak-z-ryzem-i-brokulami' }] },
  { in: 'placki ziemniaczane ze śmietaną', items: [{ id: 'placki-ze-smietana' }], note: '„ze” jako łącznik' },
  { in: '3 kromki chleba z masłem i miodem', items: [{ id: 'kanapka', qty: 3, unit: 'kromka', ch: ['add:miod'] }] },
  { in: 'kawa z mlekiem owsianym', items: [{ id: 'kawa-z-mlekiem', ch: ['variant:mleko-owsiane'] }], note: 'alias dania + wariant dodatku' },
  { in: 'herbata z miodem i cytryną', items: [{ id: 'herbata-z-cytryna', ch: ['add:miod'] }] },
  { in: 'ryż z warzywami', items: [{ id: 'ryz', ch: ['add:warzywa'] }] },
  { in: 'pierś z kurczaka z grilla', items: [{ id: 'kurczak', ch: [] }], note: '„z grilla” to sposób przygotowania' },
  { in: 'bułki z szynką, 2 sztuki', items: [{ id: 'bulka-z-szynka', qty: 2 }], note: 'ilość po przecinku' },
  // --- „bez X”, „dużo X” ---
  { in: 'bułka z szynką bez masła', items: [{ id: 'bulka-z-szynka', ch: ['remove:maslo'] }] },
  { in: 'bułka z szynką, bez masła', items: [{ id: 'bulka-z-szynka', ch: ['remove:maslo'] }] },
  { in: 'bułka żytnia z szynką, dużo masła', items: [{ id: 'bulka-z-szynka', ch: ['variant:bulka-zytnia', 'scale:maslo'] }] },
  { in: 'bułka z dużą ilością masła', items: [{ id: 'bulka-z-maslem', ch: ['scale:maslo'] }] },
  { in: 'herbata bez cukru', items: [{ id: 'herbata', kind: 'food', ch: ['remove:cukier'] }] },
  { in: 'kawa z mlekiem bez cukru', items: [{ id: 'kawa-z-mlekiem', ch: ['remove:cukier'] }] },
  // --- wiele pozycji ---
  { in: '2 jajka i kawa z mlekiem', items: [{ id: 'jajko', qty: 2 }, { id: 'kawa-z-mlekiem' }] },
  { in: 'bułka, masło, dżem', items: [{ id: 'bulka' }, { id: 'maslo' }, { id: 'dzem' }] },
  { in: 'jajecznica + kawa + sok', items: [{ id: 'jajecznica' }, { id: 'kawa' }, { id: 'sok-pomaranczowy' }] },
  { in: 'zupa pomidorowa oraz 2 kotlety mielone', items: [{ id: 'zupa-pomidorowa' }, { id: 'kotlet-mielony', qty: 2 }] },
  { in: 'kawa\njabłko', items: [{ id: 'kawa' }, { id: 'jablko' }] },
  { in: 'kawa 2 jajka', items: [{ id: 'kawa' }, { id: 'jajko', qty: 2 }], note: 'bez separatora' },
  { in: 'ziemniaki z koperkiem, schabowy i mizeria', items: [{ id: 'ziemniaki', ch: ['add:szczypiorek'] }, { id: 'kotlet-schabowy' }, { id: 'mizeria' }] },
  { in: 'bułka z szynką i ser', items: [{ id: 'bulka-z-szynka' }, { id: 'ser-zolty' }], note: 'mianownik po „i” = nowa pozycja' },
  { in: 'ciastko do kawy', items: [{ id: 'ciastko' }, { id: 'kawa' }] },
  // --- bez polskich znaków ---
  { in: 'bulka z szynka', items: [{ id: 'bulka-z-szynka', conf: 'lt1' }] },
  { in: 'zolty ser', items: [{ id: 'ser-zolty', conf: 'lt1' }] },
  { in: 'pol szklanki mleka', items: [{ id: 'mleko', qty: 0.5 }] },
  { in: 'duza bulka zytnia z szynka', items: [{ id: 'bulka-z-szynka', size: 'large', ch: ['variant:bulka-zytnia'] }] },
  { in: 'BUŁKA Z SZYNKĄ!', items: [{ id: 'bulka-z-szynka', conf: 1 }] },
  // --- literówki ---
  { in: 'bułak', items: [{ id: 'bulka', conf: 'lt1' }] },
  { in: 'jajecznca', items: [{ id: 'jajecznica', conf: 'lt1' }] },
  { in: 'bułka żytna z szynką', items: [{ id: 'bulka-z-szynka', conf: 'lt1', ch: ['variant:bulka-zytnia'] }] },
  { in: 'spagetti bolonese', items: [{ id: 'spaghetti-bolognese', conf: 'lt1' }] },
  // --- niezrozumiane, puste, posiłek ---
  { in: '', items: [] },
  { in: '   ', items: [] },
  { in: 'kawior', items: [], unknown: ['kawior'] },
  { in: 'bułka i kawior', items: [{ id: 'bulka' }], unknown: ['kawior'] },
  { in: 'bułka z kawiorem', items: [{ id: 'bulka' }], unknown: ['kawiorem'] },
  { in: 'xyz 123', items: [], unknown: ['xyz 123'] },
  { in: 'bez cukru', items: [], unknown: ['bez cukru'], note: 'negacja bez pozycji' },
  { in: 'na śniadanie owsianka', items: [{ id: 'owsianka' }], meal: 'breakfast' },
  { in: 'obiad: rosół z makaronem', items: [{ id: 'rosol-z-makaronem' }], meal: 'lunch' },
];

const db = testDb();
const parser = new RuleParser(db);

function changesOf(it: ParsedItem): string[] {
  return it.changes.map((c) => `${c.op}:${c.foodId}`);
}

describe('parser — tabela przypadków', () => {
  it(`ma co najmniej 60 przypadków (jest ${CASES.length})`, () => {
    expect(CASES.length).toBeGreaterThanOrEqual(60);
  });

  for (const c of CASES) {
    it(`${JSON.stringify(c.in)}${c.note ? ` — ${c.note}` : ''}`, () => {
      const r = parser.parse(c.in);
      expect(r.items.map((i) => i.matchedId), 'pozycje').toEqual(c.items.map((e) => e.id));
      c.items.forEach((e, i) => {
        const it = r.items[i]!;
        if (e.kind) expect(it.kind).toBe(e.kind);
        if (e.qty !== undefined) expect(it.quantity, 'ilość').toBeCloseTo(e.qty);
        if (e.unit !== undefined) expect(it.unit, 'jednostka').toBe(e.unit);
        if (e.size !== undefined) expect(it.size, 'rozmiar').toBe(e.size);
        if (e.factor !== undefined) expect(it.factor, 'mnożnik').toBe(e.factor);
        if (e.ch) expect(changesOf(it), 'zmiany').toEqual(e.ch);
        if (e.conf === 1) expect(it.confidence).toBe(1);
        if (e.conf === 'lt1') expect(it.confidence).toBeLessThan(1);
        expect(it.fragment.length).toBeGreaterThan(0);
      });
      expect(r.unknown, 'niezrozumiane').toEqual(c.unknown ?? []);
      if (c.meal) expect(r.mealHint).toBe(c.meal);
    });
  }
});

describe('parser — własności', () => {
  it('jest deterministyczny', () => {
    const text = 'duża bułka żytnia z szynką i serem, bez masła, 2 jajka i kawa z mlekiem';
    expect(new RuleParser(db).parse(text)).toEqual(parser.parse(text));
  });

  it('wynik prowadzi do rozbicia jak w specyfikacji', () => {
    const [it0] = parser.parse('duża bułka żytnia z szynką').items;
    const c = computeItem(db, it0!);
    expect(c.lines.map((l) => l.foodId)).toEqual(['bulka-zytnia', 'szynka', 'maslo']);
    expect(c.lines[0]!.explain).toBe('bułka żytnia 1 szt. (duża: 80 g) = 80 g → 200 kcal');
    expect(c.lines[1]!.explain).toMatch(/^szynka 2 plastry = 30 g → \d+ kcal$/);
    expect(c.lines[2]!.explain).toBe('masło 5 g → 37 kcal');
  });

  it('„bez masła” usuwa składnik domyślny z wyliczenia', () => {
    const [it0] = parser.parse('bułka z szynką bez masła').items;
    const c = computeItem(db, it0!);
    expect(c.lines.map((l) => l.foodId)).toEqual(['bulka', 'szynka']);
    expect(c.removed).toEqual(['masło']);
  });

  it('osobista definicja użytkownika ma pierwszeństwo', () => {
    const base = db.dishes.get('bulka-z-szynka')!;
    const mine: Dish = { ...base, ingredients: [{ foodId: 'bulka', qty: 1, unit: 'sztuka' }, { foodId: 'szynka', qty: 3, unit: 'plaster' }] };
    const udb = testDb([{ key: 'dish:bulka-z-szynka', kind: 'dish', id: 'bulka-z-szynka', data: mine, isNew: false, updatedAt: 1 }]);
    const [it0] = new RuleParser(udb).parse('bułka z szynką').items;
    const c = computeItem(udb, it0!);
    expect(c.lines.map((l) => [l.foodId, l.grams])).toEqual([['bulka', 60], ['szynka', 45]]);
  });

  it('nowe danie użytkownika z własnym aliasem wygrywa z sygnaturą', () => {
    const mine: Dish = { id: 'user-moja-kanapka', name: 'moja kanapka', aliases: ['bułka z szynką i ogórkiem'], ingredients: [{ foodId: 'bulka-grahamka', qty: 1, unit: 'sztuka' }, { foodId: 'szynka', qty: 3, unit: 'plaster' }, { foodId: 'ogorek-kiszony', qty: 1, unit: 'sztuka' }] };
    const udb = testDb([{ key: 'dish:user-moja-kanapka', kind: 'dish', id: 'user-moja-kanapka', data: mine, isNew: true, updatedAt: 1 }]);
    const r = new RuleParser(udb).parse('bułka z szynką i ogórkiem');
    expect(r.items.map((i) => i.matchedId)).toEqual(['user-moja-kanapka']);
  });

  it('jest szybki (długi tekst < 50 ms po rozgrzaniu)', () => {
    const text = Array(5).fill('duża bułka żytnia z szynką i serem, 2 jajka, kawa z mlekiem i cukrem').join(', ');
    parser.parse(text);
    const t0 = performance.now();
    parser.parse(text);
    expect(performance.now() - t0).toBeLessThan(50);
  });
});
