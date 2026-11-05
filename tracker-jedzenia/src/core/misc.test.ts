import { describe, expect, it } from 'vitest';
import { addDays, formatDatePl, guessMeal, localDate } from './meals.ts';
import { quickEntries, summarizeDays, weekSummary } from './stats.ts';
import { makeBackup, parseBackup } from './backup.ts';
import { DEFAULT_SETTINGS } from './goals.ts';
import { fmtNum, plural } from './format.ts';
import { buildDb } from './db.ts';
import { DEFAULT_DATA } from './defaults.ts';
import type { LogEntry } from './types.ts';

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
});

describe('format i baza', () => {
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
