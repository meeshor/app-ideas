// Stosuje dane USDA (data-src/usda.json) do produktów z powiązaniem 'same' i tworzy raport porównania.
import { readFileSync } from 'node:fs';
import type { Food, Macros } from '../src/core/types.ts';
import { USDA_LINKS, type UsdaLink } from '../data-src/usda-map.ts';
import type { UsdaFood } from './usda-sync.ts';

const USDA: Record<string, UsdaFood> = JSON.parse(readFileSync(new URL('../data-src/usda.json', import.meta.url), 'utf8'));
const LINKS = new Map(USDA_LINKS.map((l) => [l[0], l]));
/** Produkty, które zachowują węglowodany bez błonnika (patrz data-src/usda-map.ts). */
const NET_CARBS = new Set(['kakao-proszek']);
/** Próg „istotnej różnicy” w raporcie: kcal względnie, makro bezwzględnie w gramach na 100 g. */
const KCAL_DIFF = 0.15;
const MACRO_DIFF_G = 3;
const SOURCE_PREFIX = 'USDA FoodData Central, SR Legacy (2018)';

const round1 = (x: number) => Math.round(x * 10) / 10;

export function usdaMacros(u: UsdaFood): Macros {
  return { kcal: Math.round(u.kcal), carbs: round1(u.carbs), protein: round1(u.protein), fat: round1(u.fat) };
}

function usdaOf(link: UsdaLink) {
  const u = USDA[String(link[1])];
  if (!u) throw new Error(`Brak danych USDA ${link[1]} dla ${link[0]} — uruchom npm run usda`);
  return u;
}

export function applyUsda(foods: Food[]): Food[] {
  for (const id of LINKS.keys()) if (!foods.some((f) => f.id === id)) throw new Error(`usda-map: nieznany produkt ${id}`);
  return foods.map((f) => {
    const link = LINKS.get(f.id);
    if (!link || link[2] !== 'same') return f;
    const u = usdaOf(link);
    const note = link[3] ? `; ${link[3]}` : '';
    return { ...f, per100: usdaMacros(u), source: `${SOURCE_PREFIX} #${link[1]}: ${u.desc}${note}`, verified: true };
  });
}

function differs(a: Macros, b: Macros) {
  return (
    Math.abs(a.kcal - b.kcal) > KCAL_DIFF * Math.max(b.kcal, 20) ||
    (['carbs', 'protein', 'fat'] as const).some((k) => Math.abs(a[k] - b[k]) > MACRO_DIFF_G)
  );
}

const fmt = (m: Macros) => `${m.kcal} / ${m.carbs} / ${m.protein} / ${m.fat}`;

export function usdaReport(foods: Food[]): string {
  const rows = { same: [] as string[], ref: [] as string[] };
  let changed = 0;
  for (const f of foods) {
    const link = LINKS.get(f.id);
    if (!link || !f.per100) continue;
    const u = usdaMacros(usdaOf(link));
    const diff = differs(f.per100, u);
    if (link[2] === 'same' && diff) changed++;
    const mark = diff ? '**≠**' : '≈';
    rows[link[2]].push(`| ${f.name} | ${fmt(f.per100)} | ${fmt(u)} | ${mark} | [${link[1]}](https://fdc.nal.usda.gov/food-details/${link[1]}/nutrients) ${usdaOf(link).desc} | ${link[3] ?? ''} |`);
  }
  const unlinked = foods.filter((f) => f.per100 && !LINKS.has(f.id)).map((f) => f.name);
  const head = '| Produkt | Przed (kcal / W / B / T) | USDA | | Pozycja USDA | Uwagi |\n|---|---|---|---|---|---|';
  return `# Weryfikacja wartości odżywczych z USDA

Plik generuje \`npm run data\` (scripts/usda-apply.ts) — nie edytuj ręcznie. Wartości na 100 g.
Źródło: USDA FoodData Central, SR Legacy (kwiecień 2018), powiązania w \`data-src/usda-map.ts\`.
„≠” oznacza różnicę powyżej ${KCAL_DIFF * 100}% kcal albo ${MACRO_DIFF_G} g któregokolwiek makro.
Węglowodany ogółem, z błonnikiem (jak w USDA)${NET_CARBS.size ? '; wyjątek: kakao w proszku' : ''}.

## Ten sam produkt — wartości z USDA, \`verified: true\` (${rows.same.length})

Kolumna „Przed” to wartości z \`data-src/foods.ts\`; w aplikacji są już wartości USDA.
Istotnie poprawionych: **${changed}**.

${head}
${rows.same.join('\n')}

## Polski produkt różni się od amerykańskiego — zostają nasze wartości (${rows.ref.length})

USDA tylko dla porównania; te produkty zostają \`verified: false\`.

${head}
${rows.ref.join('\n')}

## Bez odpowiednika w USDA (${unlinked.length})

${unlinked.join(', ')}.

Do sprawdzenia z etykietami lub tabelami NIZP-PZH (Kunachowicz i in., „Tabele składu i wartości odżywczej żywności”).
`;
}
