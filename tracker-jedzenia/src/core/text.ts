// Normalizacja i tokenizacja tekstu wejściowego.

const DIACRITICS: Record<string, string> = {
  ą: 'a', ć: 'c', ę: 'e', ł: 'l', ń: 'n', ó: 'o', ś: 's', ź: 'z', ż: 'z',
};

/** Usuwa polskie znaki (i inne akcenty): „bułką” → „bulka”. */
export function stripDiacritics(s: string): string {
  return s
    .replace(/[ąćęłńóśźż]/g, (c) => DIACRITICS[c] ?? c)
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '');
}

/** Małe litery, NFC, jednolite spacje. */
export function normalizeBasic(s: string): string {
  return s.normalize('NFC').toLowerCase().replace(/\s+/g, ' ').trim();
}

/** Klucz porównawczy: znormalizowany i bez polskich znaków. */
export function keyOf(s: string): string {
  return stripDiacritics(normalizeBasic(s));
}

export type Token =
  | { type: 'word'; raw: string; key: string }
  | { type: 'num'; raw: string; key: string; value: number }
  | { type: 'sep'; raw: string; key: string };

/** Parsuje liczbę: „2”, „2.5”, „2,5”, „1/2”. */
export function parseNumber(s: string): number | null {
  if (/^\d+([.,]\d+)?$/.test(s)) return Number(s.replace(',', '.'));
  const frac = /^(\d+)\/(\d+)$/.exec(s);
  if (frac) {
    const d = Number(frac[2]);
    return d === 0 ? null : Number(frac[1]) / d;
  }
  return null;
}

/**
 * Tokenizacja: interpunkcja „, + ; nowa linia” → separator; „200g” → „200 g”;
 * „2,5” → liczba; „2x”/„x2” → liczba; myślniki → spacje; pozostała interpunkcja usuwana.
 */
export function tokenize(input: string): Token[] {
  let s = input.normalize('NFC').toLowerCase();
  s = s.replace(/(\d),(\d)/g, '$1.$2'); // przecinek dziesiętny
  s = s.replace(/\d+(?:\.\d+)?\s*%/g, ' '); // „mleko 2%” — zawartość tłuszczu pomijamy
  s = s.replace(/[\n\r;,+]/g, ' , ');
  s = s.replace(/(\d)\s*(?:x|×)\b/g, '$1 '); // „2x” → „2”
  s = s.replace(/\b(?:x|×)\s*(\d)/g, ' $1'); // „x2” → „2”
  s = s.replace(/(\d)([a-ząćęłńóśźż]+)/g, '$1 $2'); // „200g” → „200 g”
  s = s.replace(/([a-ząćęłńóśźż])(\d)/g, '$1 $2');
  s = s.replace(/[-–—_]/g, ' ');
  s = s.replace(/(\d)\.(?!\d)/g, '$1 '); // kropka po liczbie (koniec zdania)
  s = s.replace(/[^\p{L}\p{N}\s,./%]/gu, ' ');
  s = s.replace(/(?<!\d)\.|\.(?!\d)/g, ' ');
  const tokens: Token[] = [];
  for (const part of s.split(/\s+/)) {
    if (!part) continue;
    if (part === ',') {
      if (tokens.length && tokens[tokens.length - 1]!.type !== 'sep') tokens.push({ type: 'sep', raw: ',', key: ',' });
      continue;
    }
    const n = parseNumber(part);
    if (n !== null) {
      tokens.push({ type: 'num', raw: part, key: part, value: n });
      continue;
    }
    const clean = part.replace(/[/%]/g, '');
    if (!clean) continue;
    tokens.push({ type: 'word', raw: clean, key: stripDiacritics(clean) });
  }
  while (tokens.length && tokens[0]!.type === 'sep') tokens.shift();
  while (tokens.length && tokens[tokens.length - 1]!.type === 'sep') tokens.pop();
  return tokens;
}

export function tokensText(tokens: readonly Token[]): string {
  return tokens
    .map((t) => t.raw)
    .join(' ')
    .replace(/ ,/g, ',')
    .replace(/(\d)\.(\d)/g, '$1,$2');
}
