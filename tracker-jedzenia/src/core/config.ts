// Wszystkie stałe liczbowe rdzenia w jednym miejscu.
// Oznaczenie „do strojenia” = wartość dobrana rozsądnie, bez źródła; warto ją kalibrować na realnych wpisach.
// Dane o produktach, porcjach, jednostkach i mnożnikach rozmiaru są w data/*.json (nie tutaj).

import type { Activity, GoalKind, MacroSplit, Meal } from './types.ts';

export const CONFIG = {
  parser: {
    /** Maksymalna długość aliasu w słowach przy szukaniu najdłuższego dopasowania. */
    maxAliasWords: 6,
    /** Dopasowanie przybliżone: minimalna długość słowa (krótsze tylko dokładnie). Do strojenia. */
    fuzzyMinLength: 4,
    /** Maksymalna odległość edycyjna (Damerau-Levenshtein, OSA) zależnie od długości słowa. Do strojenia. */
    fuzzyMaxDistance(len: number): number {
      if (len < 4) return 0;
      if (len <= 7) return 1;
      return 2;
    },
    confidence: {
      exact: 1,
      /** Dopasowanie tylko po usunięciu polskich znaków („bulka”). */
      noDiacritics: 0.95,
      /** Dopasowanie przybliżone (literówka). Do strojenia. */
      fuzzy: 0.6,
      /** Mnożnik pewności, gdy użyto porcji ogólnej zamiast porcji produktu. Do strojenia. */
      fallbackUnit: 0.8,
      /** Mnożnik pewności, gdy rozmiar policzono mnożnikiem globalnym. Do strojenia. */
      fallbackSize: 0.9,
    },
    /** Końcówki narzędnika: „i serem” po „z szynką” traktujemy jako kolejny dodatek. */
    instrumentalEndings: ['em', 'iem', 'ą', 'ami', 'mi'],
  },
  calculator: {
    /** Domyślna gęstość g/ml, gdy produkt jej nie podaje. */
    defaultDensity: 1,
    /** Gramy porcji domyślnej, gdy produkt nie ma żadnych porcji. Do strojenia. */
    defaultPortionGrams: 100,
  },
  meals: {
    /** Zgadywanie posiłku po godzinie [od, do) w godzinach lokalnych. Do strojenia. */
    byHour: [
      { from: 4, to: 11, meal: 'breakfast' },
      { from: 11, to: 13, meal: 'snack' },
      { from: 13, to: 17, meal: 'lunch' },
      { from: 17, to: 21, meal: 'dinner' },
    ] as { from: number; to: number; meal: Meal }[],
    fallback: 'snack' as Meal,
  },
  goals: {
    /** Mifflin-St Jeor (1990): 10·kg + 6,25·cm − 5·wiek + s; s = +5 (M), −161 (K). */
    mifflin: { weight: 10, height: 6.25, age: -5, male: 5, female: -161 },
    /** Współczynniki aktywności (typowe wartości PAL z literatury żywieniowej). */
    activity: {
      sedentary: 1.2,
      light: 1.375,
      moderate: 1.55,
      active: 1.725,
      very_active: 1.9,
    } as Record<Activity, number>,
    /** Korekta energii względem celu. Do strojenia (często spotykane −15% / +10%). */
    goalFactor: { lose: 0.85, maintain: 1, gain: 1.1 } as Record<GoalKind, number>,
    /** Domyślny podział energii (% kcal) — popularny „zrównoważony” podział, do zmiany przez użytkownika. */
    defaultSplit: { carbs: 50, protein: 20, fat: 30 } as MacroSplit,
    /** kcal na gram: węglowodany 4, białko 4, tłuszcz 9 (współczynniki Atwatera). */
    kcalPerGram: { carbs: 4, protein: 4, fat: 9 },
    /** Cel energetyczny, gdy profil nie jest uzupełniony (orientacyjny). */
    defaultKcal: 2000,
    /** Dolna granica sugerowanego celu, żeby nie podpowiadać skrajnie niskich wartości. */
    minKcal: { female: 1200, male: 1500 },
  },
  history: {
    recentLimit: 6,
    frequentLimit: 6,
  },
} as const;
