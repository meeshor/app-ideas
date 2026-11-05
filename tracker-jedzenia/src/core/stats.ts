// Podsumowania historii i lista „szybkiego ponawiania”.

import { addDays } from './meals.ts';
import { sumMacros } from './calculator.ts';
import { keyOf } from './text.ts';
import type { LogEntry, Macros } from './types.ts';

export interface DaySummary {
  date: string;
  totals: Macros;
  count: number;
}

export function summarizeDays(entries: readonly LogEntry[]): DaySummary[] {
  const by = new Map<string, LogEntry[]>();
  for (const e of entries) by.set(e.date, [...(by.get(e.date) ?? []), e]);
  return [...by.entries()]
    .map(([date, list]) => ({ date, totals: sumMacros(list.map((e) => e.totals)), count: list.length }))
    .sort((a, b) => b.date.localeCompare(a.date));
}

export interface WeekSummary {
  from: string;
  to: string;
  daysWithEntries: number;
  average: Macros;
}

/** Średnia z 7 dni kończących się w `endDate`, liczona tylko z dni, w których coś zapisano. */
export function weekSummary(entries: readonly LogEntry[], endDate: string): WeekSummary {
  const from = addDays(endDate, -6);
  const days = summarizeDays(entries.filter((e) => e.date >= from && e.date <= endDate));
  const n = days.length;
  const total = sumMacros(days.map((d) => d.totals));
  const avg = n ? { kcal: total.kcal / n, carbs: total.carbs / n, protein: total.protein / n, fat: total.fat / n } : total;
  return { from, to: endDate, daysWithEntries: n, average: avg };
}

export interface QuickEntry {
  key: string;
  text: string;
  count: number;
  lastAt: number;
  kcal: number;
  entry: LogEntry;
}

/** Ostatnie i najczęstsze wpisy (po znormalizowanym tekście). */
export function quickEntries(entries: readonly LogEntry[], limits: { recent: number; frequent: number }): { recent: QuickEntry[]; frequent: QuickEntry[] } {
  const by = new Map<string, QuickEntry>();
  for (const e of entries) {
    const key = keyOf(e.text);
    const q = by.get(key);
    if (!q) by.set(key, { key, text: e.text, count: 1, lastAt: e.createdAt, kcal: e.totals.kcal, entry: e });
    else {
      q.count++;
      if (e.createdAt > q.lastAt) Object.assign(q, { lastAt: e.createdAt, text: e.text, kcal: e.totals.kcal, entry: e });
    }
  }
  const all = [...by.values()];
  const recent = [...all].sort((a, b) => b.lastAt - a.lastAt).slice(0, limits.recent);
  const recentKeys = new Set(recent.map((r) => r.key));
  const frequent = all
    .filter((q) => q.count > 1 && !recentKeys.has(q.key))
    .sort((a, b) => b.count - a.count || b.lastAt - a.lastAt)
    .slice(0, limits.frequent);
  return { recent, frequent };
}
