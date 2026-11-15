import { describe, expect, it } from 'vitest';
import { addDays, formatDatePl, guessMeal, localDate } from './meals.ts';
import { quickEntries, summarizeDays, weekSummary } from './stats.ts';
import { makeBackup, mergeBackup, parseBackup } from './backup.ts';
import { DEFAULT_SETTINGS } from './goals.ts';
import { fmtNum, plural, qtyPrefix } from './format.ts';
import { buildDb } from './db.ts';
import { DEFAULT_DATA } from './defaults.ts';
import type { LogEntry, UserOverride } from './types.ts';

const entry = (id: string, date: string, text: string, kcal: number, createdAt: number): LogEntry => ({
  id, date, time: '12:00', meal: 'lunch', text, items: [], computed: [], totals: { kcal, carbs: 0, protein: 0, fat: 0 }, createdAt,
});

describe('posiłki i daty', () => {
  it('zgaduje posiłek po godzinie', () => {
    expect(guessMeal(7)).toBe('breakfast');
    expect(guessMeal(14)).toBe('lunch');
    expect(guessMeal(19)).toBe('dinner');
    expect(guessMeal(23)).toBe('snack');
  });
  it('daty', () => {
    expect(addDays('2026-03-01', -1)).toBe('2026-02-28');
    expect(localDate(new Date(2026, 10, 5, 23, 59))).toBe('2026-11-05');
    expect(formatDatePl('2026-11-05')).toBe('czwartek, 5 listopada');
  });
});

describe('historia', () => {
  const es = [entry('a', '2026-11-05', 'Kawa z mlekiem', 40, 3), entry('b', '2026-11-05', 'bułka', 200, 2), entry('c', '2026-11-03', 'kawa z mlekiem', 40, 1), entry('d', '2026-10-20', 'pizza', 1000, 0)];
  it('sumy dni i średnia tygodnia z dni z wpisami', () => {
    expect(summarizeDays(es).map((d) => [d.date, d.totals.kcal])).toEqual([['2026-11-05', 240], ['2026-11-03', 40], ['2026-10-20', 1000]]);
    const w = weekSummary(es, '2026-11-05');
    expect(w.daysWithEntries).toBe(2);
    expect(w.average.kcal).toBe(140);
  });
  it('ostatnie i częste wpisy', () => {
    const q = quickEntries(es, { recent: 1, frequent: 3 });
    expect(q.recent.map((x) => x.text)).toEqual(['Kawa z mlekiem']);
    expect(q.recent[0]!.count).toBe(2);
    expect(q.frequent).toEqual([]);
  });
});

describe('kopia zapasowa', () => {
  it('eksport → import', () => {
    const b = makeBackup({ settings: DEFAULT_SETTINGS, overrides: [], entries: [entry('a', '2026-11-05', 'x', 1, 1)] });
    const r = parseBackup(JSON.stringify(b));
    expect(r.ok).toBe(true);
  });
  it('odrzuca złe pliki', () => {
    expect(parseBackup('nie json').ok).toBe(false);
    expect(parseBackup('{"app":"inna"}').ok).toBe(false);
    expect(parseBackup(JSON.stringify({ app: 'zjadlem', version: 1, settings: {}, overrides: [], entries: [{ id: 1 }] })).ok).toBe(false);
  });
  it('scalanie: nowe dochodzą, przy konflikcie wygrywa nowsza zmiana, ustawienia zostają', () => {
    const ov = (key: string, updatedAt: number, name: string): UserOverride => ({ key, kind: 'food', id: key, data: { id: key, name }, isNew: true, updatedAt });
    const mine = { settings: { ...DEFAULT_SETTINGS, theme: 'dark' as const }, overrides: [ov('a', 5, 'moje a'), ov('b', 5, 'moje b')], entries: [entry('x', '2026-11-05', 'stary', 1, 10), entry('y', '2026-11-05', 'mój', 1, 10)] };
    const other = makeBackup({
      settings: { ...DEFAULT_SETTINGS, theme: 'light' },
      overrides: [ov('a', 9, 'ich a'), ov('b', 1, 'ich b'), ov('c', 1, 'ich c')],
      entries: [{ ...entry('x', '2026-11-05', 'poprawiony', 2, 10), updatedAt: 20 }, entry('y', '2026-11-05', 'ich starszy', 1, 5), entry('z', '2026-11-06', 'nowy', 3, 30)],
    });
    const { data, stats } = mergeBackup(mine, other);
    expect(stats).toEqual({ entriesAdded: 1, entriesUpdated: 1, overridesAdded: 1, overridesUpdated: 1 });
    expect(data.settings.theme).toBe('dark');
    expect(data.entries.map((e) => e.text).sort()).toEqual(['mój', 'nowy', 'poprawiony']);
    expect(data.overrides.map((o) => (o.data as { name: string }).name).sort()).toEqual(['ich a', 'ich c', 'moje b']);
  });
});

describe('format i baza', () => {
  it('przedrostek ilości: porcje vs miary', () => {
    expect(qtyPrefix(1, null)).toBe('');
    expect(qtyPrefix(2, 'sztuka')).toBe('2 × ');
    expect(qtyPrefix(150, 'g')).toBe('150 g ');
    expect(qtyPrefix(0.5, 'l')).toBe('0,5 l ');
  });
  it('liczby i odmiana liczebnikowa', () => {
    expect(fmtNum(1.25, 2)).toBe('1,25');
    expect(fmtNum(72)).toBe('72');
    expect([1, 2, 5, 12, 22, 1.5].map((n) => plural(n, 'plaster', 'plastry', 'plastrów'))).toEqual(['plaster', 'plastry', 'plastrów', 'plastrów', 'plastry', 'plastry']);
  });
  it('nadpisania użytkownika mają pierwszeństwo i można je usunąć', () => {
    const bulka = DEFAULT_DATA.foods.find((f) => f.id === 'bulka')!;
    const db = buildDb(DEFAULT_DATA, [
      { key: 'food:bulka', kind: 'food', id: 'bulka', data: { ...bulka, portions: { sztuka: 70 } }, isNew: false, updatedAt: 1 },
      { key: 'food:moja', kind: 'food', id: 'moja', data: { id: 'moja', name: 'moja bułka', per100: { kcal: 1, carbs: 0, protein: 0, fat: 0 } }, isNew: true, updatedAt: 1 },
      { key: 'dish:kanapka', kind: 'dish', id: 'kanapka', data: null, isNew: false, updatedAt: 1 },
    ]);
    expect(db.foods.get('bulka')!.portions!.sztuka).toBe(70);
    expect(db.origin.get('food:bulka')).toBe('changed');
    expect(db.origin.get('food:moja')).toBe('user');
    expect(db.dishes.has('kanapka')).toBe(false);
  });
});
