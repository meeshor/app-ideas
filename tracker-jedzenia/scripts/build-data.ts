// Generuje data/*.json z data-src/*.ts: dopisuje formy odmiany (reguły z src/core/inflect.ts)
// do form wpisanych ręcznie. Uruchomienie: npm run data
import { writeFileSync } from 'node:fs';
import { FOODS } from '../data-src/foods.ts';
import { DISHES } from '../data-src/dishes.ts';
import { MODIFIERS } from '../data-src/modifiers.ts';
import { inflectAll } from '../src/core/inflect.ts';

function withForms<T extends { name: string; aliases?: string[]; forms?: string[] }>(x: T): T {
  const base = [x.name, ...(x.aliases ?? [])];
  const forms = new Set([...inflectAll(base), ...(x.forms ?? []).map((f) => f.toLowerCase())]);
  for (const b of base) forms.delete(b.toLowerCase());
  return { ...x, forms: [...forms].sort((a, b) => a.localeCompare(b, 'pl')) };
}

/** JSON z tablicami prymitywów w jednej linii (czytelniejszy diff). */
function stringify(v: unknown, indent = 0): string {
  const pad = '  '.repeat(indent);
  const pad1 = '  '.repeat(indent + 1);
  if (Array.isArray(v)) {
    if (v.every((x) => typeof x !== 'object' || x === null)) return JSON.stringify(v);
    if (v.length === 0) return '[]';
    return '[\n' + v.map((x) => pad1 + stringify(x, indent + 1)).join(',\n') + '\n' + pad + ']';
  }
  if (v && typeof v === 'object') {
    const entries = Object.entries(v).filter(([, x]) => x !== undefined);
    if (entries.length === 0) return '{}';
    const flat = entries.every(([, x]) => typeof x !== 'object' || x === null);
    if (flat && entries.length <= 6) return JSON.stringify(v).replace(/,"/g, ', "').replace(/":/g, '": ');
    return '{\n' + entries.map(([k, x]) => `${pad1}${JSON.stringify(k)}: ${stringify(x, indent + 1)}`).join(',\n') + '\n' + pad + '}';
  }
  return JSON.stringify(v);
}

const foods = FOODS.map(withForms);
const dishes = DISHES.map(withForms);
const dir = new URL('../data/', import.meta.url);
writeFileSync(new URL('foods.json', dir), stringify(foods) + '\n');
writeFileSync(new URL('dishes.json', dir), stringify(dishes) + '\n');
writeFileSync(new URL('modifiers.json', dir), stringify(MODIFIERS) + '\n');
const formCount = foods.reduce((n, f) => n + (f.forms?.length ?? 0), 0);
console.log(`produkty: ${foods.length} (w tym wariantów: ${foods.filter((f) => f.parentId).length}), dania: ${dishes.length}, formy produktów: ${formCount}`);
