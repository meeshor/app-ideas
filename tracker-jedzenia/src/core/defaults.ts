// Dane domyślne (data/*.json) — dołączane do buildu, wczytywane przy starcie.
import foods from '../../data/foods.json';
import dishes from '../../data/dishes.json';
import modifiers from '../../data/modifiers.json';
import type { Dish, Food, ModifiersData } from './types.ts';
import type { DefaultData } from './db.ts';

export const DEFAULT_DATA: DefaultData = {
  foods: foods as Food[],
  dishes: dishes as Dish[],
  modifiers: modifiers as unknown as ModifiersData,
};
