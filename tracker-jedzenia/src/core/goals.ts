// Orientacyjne cele dzienne: Mifflin-St Jeor × współczynnik aktywności × korekta celu, podział makro.
// To szacunek, nie zalecenie medyczne.

import { CONFIG } from './config.ts';
import type { Macros, MacroSplit, Profile, Settings } from './types.ts';

export interface Goals extends Macros {
  bmr: number | null;
  tdee: number | null;
  source: 'profile' | 'default' | 'manual';
}

/** Podstawowa przemiana materii (kcal/dobę), wzór Mifflin-St Jeor. */
export function bmrMifflin(p: Pick<Profile, 'sex' | 'age' | 'heightCm' | 'weightKg'>): number {
  const c = CONFIG.goals.mifflin;
  return c.weight * p.weightKg + c.height * p.heightCm + c.age * p.age + (p.sex === 'male' ? c.male : c.female);
}

export function isValidProfile(p: Profile | null | undefined): p is Profile {
  return !!p && p.age >= 14 && p.age <= 110 && p.heightCm >= 120 && p.heightCm <= 230 && p.weightKg >= 30 && p.weightKg <= 300;
}

/** Gramy makro z energii i podziału procentowego (4/4/9 kcal/g). */
export function macrosFromSplit(kcal: number, split: MacroSplit): Macros {
  const k = CONFIG.goals.kcalPerGram;
  const sum = split.carbs + split.protein + split.fat || 100;
  return {
    kcal,
    carbs: Math.round((kcal * (split.carbs / sum)) / k.carbs),
    protein: Math.round((kcal * (split.protein / sum)) / k.protein),
    fat: Math.round((kcal * (split.fat / sum)) / k.fat),
  };
}

export function computeGoals(settings: Pick<Settings, 'profile' | 'split' | 'manualGoals'>): Goals {
  const split = settings.split ?? CONFIG.goals.defaultSplit;
  let kcal: number = CONFIG.goals.defaultKcal;
  let bmr: number | null = null;
  let tdee: number | null = null;
  let source: Goals['source'] = 'default';
  const p = settings.profile;
  if (isValidProfile(p)) {
    bmr = bmrMifflin(p);
    tdee = bmr * CONFIG.goals.activity[p.activity];
    kcal = Math.max(CONFIG.goals.minKcal[p.sex], tdee * CONFIG.goals.goalFactor[p.goal]);
    kcal = Math.round(kcal / 10) * 10;
    source = 'profile';
  }
  const m = settings.manualGoals;
  if (m && m.kcal) kcal = m.kcal;
  const fromSplit = macrosFromSplit(kcal, split);
  const manualAny = !!m && Object.values(m).some((v) => typeof v === 'number' && v > 0);
  return {
    kcal,
    carbs: m?.carbs || fromSplit.carbs,
    protein: m?.protein || fromSplit.protein,
    fat: m?.fat || fromSplit.fat,
    bmr: bmr === null ? null : Math.round(bmr),
    tdee: tdee === null ? null : Math.round(tdee),
    source: manualAny ? 'manual' : source,
  };
}

export const DEFAULT_SETTINGS: Settings = {
  profile: null,
  split: { ...CONFIG.goals.defaultSplit },
  manualGoals: null,
  sizeMultipliers: {},
  theme: 'auto',
};
