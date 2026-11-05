import { describe, expect, it } from 'vitest';
import { bmrMifflin, computeGoals, DEFAULT_SETTINGS, macrosFromSplit } from './goals.ts';
import type { Profile } from './types.ts';

const p: Profile = { sex: 'male', age: 30, heightCm: 180, weightKg: 80, activity: 'moderate', goal: 'maintain' };

describe('cele', () => {
  it('Mifflin-St Jeor', () => {
    expect(bmrMifflin(p)).toBe(10 * 80 + 6.25 * 180 - 5 * 30 + 5); // 1780
    expect(bmrMifflin({ ...p, sex: 'female' })).toBe(1780 - 166);
  });
  it('cel z profilu: BMR × aktywność × korekta', () => {
    const g = computeGoals({ ...DEFAULT_SETTINGS, profile: p });
    expect(g.tdee).toBe(Math.round(1780 * 1.55));
    expect(g.kcal).toBe(Math.round((1780 * 1.55) / 10) * 10);
    expect(g.source).toBe('profile');
    const lose = computeGoals({ ...DEFAULT_SETTINGS, profile: { ...p, goal: 'lose' } });
    expect(lose.kcal).toBeLessThan(g.kcal);
  });
  it('bez profilu: wartość domyślna; minimum dla redukcji', () => {
    expect(computeGoals(DEFAULT_SETTINGS).kcal).toBe(2000);
    const tiny = computeGoals({ ...DEFAULT_SETTINGS, profile: { sex: 'female', age: 80, heightCm: 150, weightKg: 40, activity: 'sedentary', goal: 'lose' } });
    expect(tiny.kcal).toBe(1200);
  });
  it('podział makro 4/4/9 i ręczne nadpisanie', () => {
    expect(macrosFromSplit(2000, { carbs: 50, protein: 20, fat: 30 })).toEqual({ kcal: 2000, carbs: 250, protein: 100, fat: 67 });
    const g = computeGoals({ ...DEFAULT_SETTINGS, manualGoals: { kcal: 1800, protein: 140 } });
    expect(g).toMatchObject({ kcal: 1800, protein: 140, carbs: 225, source: 'manual' });
  });
});
