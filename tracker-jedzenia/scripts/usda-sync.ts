// Wyciąga z bazy USDA FoodData Central (SR Legacy, CSV) makro pozycji wskazanych w data-src/usda-map.ts
// i zapisuje je do data-src/usda.json (commitowany, więc `npm run data` nie potrzebuje CSV).
// Uruchomienie: npm run usda -- <katalog z food.csv i food_nutrient.csv>
// Paczka: https://fdc.nal.usda.gov/download-datasets (SR Legacy, CSV).
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { USDA_LINKS } from '../data-src/usda-map.ts';

export interface UsdaFood {
  desc: string;
  kcal: number;
  carbs: number;
  fiber: number;
  protein: number;
  fat: number;
  alcohol?: number;
}

const NUTRIENTS: Record<string, keyof Omit<UsdaFood, 'desc'>> = {
  '1008': 'kcal',
  '1005': 'carbs',
  '1079': 'fiber',
  '1003': 'protein',
  '1004': 'fat',
  '1018': 'alcohol',
};

const dir = process.argv[2];
if (!dir) {
  console.error('Podaj katalog z rozpakowanym CSV SR Legacy: npm run usda -- <katalog>');
  process.exit(1);
}

const wanted = new Set(USDA_LINKS.map(([, fdc]) => String(fdc)));
const cells = (line: string) => line.trim().slice(1, -1).split('","');
const rows = (file: string) => readFileSync(join(dir, file), 'utf8').split('\n').slice(1).filter(Boolean).map(cells);

const out: Record<string, UsdaFood> = {};
for (const [id, , desc] of rows('food.csv'))
  if (id && wanted.has(id)) out[id] = { desc: desc!, kcal: 0, carbs: 0, fiber: 0, protein: 0, fat: 0 };
for (const [, fdc, nutrient, amount] of rows('food_nutrient.csv')) {
  const key = NUTRIENTS[nutrient!];
  const food = out[fdc!];
  if (!key || !food || (key === 'alcohol' && Number(amount) === 0)) continue;
  food[key] = Number(amount);
}

const missing = [...wanted].filter((id) => !out[id]);
if (missing.length) {
  console.error(`Brak w bazie USDA: ${missing.join(', ')}`);
  process.exit(1);
}
const sorted = Object.fromEntries(Object.entries(out).sort(([a], [b]) => Number(a) - Number(b)));
writeFileSync(new URL('../data-src/usda.json', import.meta.url), JSON.stringify(sorted, null, 1) + '\n');
console.log(`pozycje USDA: ${Object.keys(sorted).length}`);
