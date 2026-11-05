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
