import { describe, expect, it } from 'vitest';
import { dailySeries, daysOnTarget } from './stats.ts';
import type { LogEntry } from './types.ts';

function entry(date: string, kcal: number): LogEntry {
  return { date, totals: { kcal, carbs: 0, protein: 0, fat: 0 } } as unknown as LogEntry;
}

describe('dailySeries', () => {
  it('fills empty days and sums entries per day, oldest first', () => {
    const series = dailySeries([entry('2026-11-10', 500), entry('2026-11-10', 300), entry('2026-11-12', 1000)], '2026-11-12', 4);
    expect(series.map((d) => d.date)).toEqual(['2026-11-09', '2026-11-10', '2026-11-11', '2026-11-12']);
    expect(series.map((d) => d.totals.kcal)).toEqual([0, 800, 0, 1000]);
    expect(series.map((d) => d.logged)).toEqual([false, true, false, true]);
  });

  it('crosses month boundaries and ignores entries outside the range', () => {
    const series = dailySeries([entry('2026-10-31', 100), entry('2026-11-02', 200), entry('2026-10-01', 999)], '2026-11-02', 3);
    expect(series.map((d) => d.date)).toEqual(['2026-10-31', '2026-11-01', '2026-11-02']);
    expect(series.map((d) => d.totals.kcal)).toEqual([100, 0, 200]);
  });
});

describe('daysOnTarget', () => {
  it('counts logged days within tolerance of the goal', () => {
    const series = dailySeries([entry('2026-11-01', 1950), entry('2026-11-02', 2500), entry('2026-11-03', 2100)], '2026-11-04', 4);
    expect(daysOnTarget(series, 2000)).toEqual({ onTarget: 2, logged: 3 });
    expect(daysOnTarget(series, 0)).toEqual({ onTarget: 0, logged: 3 });
  });
});
