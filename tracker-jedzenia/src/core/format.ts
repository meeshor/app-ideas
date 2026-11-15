// Formatowanie liczb i form po polsku (bez Intl, żeby wynik był identyczny wszędzie).

/** „1,2”, „72”, „0,25” — przecinek dziesiętny, bez zbędnych zer. */
export function fmtNum(n: number, maxDecimals = 1): string {
  const f = 10 ** maxDecimals;
  const r = Math.round(n * f) / f;
  return String(r).replace('.', ',');
}

export function fmtKcal(n: number): string {
  return `${Math.round(n)} kcal`;
}

/** Forma liczebnikowa: 1 plaster, 2 plastry, 5 plastrów. */
export function plural(n: number, one: string, few: string, many: string): string {
  if (!Number.isInteger(n)) return few;
  const abs = Math.abs(n);
  if (abs === 1) return one;
  const d = abs % 10;
  const dd = abs % 100;
  if (d >= 2 && d <= 4 && !(dd >= 12 && dd <= 14)) return few;
  return many;
}

/** Jednostki miary, przy których ilość to masa/objętość, a nie liczba porcji. */
const MEASURE_UNITS = new Set(['g', 'dag', 'kg', 'ml', 'l']);

/**
 * Przedrostek ilości w nagłówku pozycji: „2 × ” dla porcji, „150 g ” dla miar, pusty dla 1 porcji.
 * (Bez tego „150 g ryżu” wyglądało jak „150 × ryż”.)
 */
export function qtyPrefix(quantity: number, unit: string | null): string {
  if (unit && MEASURE_UNITS.has(unit)) return `${fmtNum(quantity, 2)} ${unit} `;
  return quantity !== 1 ? `${fmtNum(quantity, 2)} × ` : '';
}
