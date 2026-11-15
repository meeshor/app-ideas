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
  return mergeNumerals(tokens);
}

// Liczebniki złożone („dwadzieścia pięć”, „sto pięćdziesiąt”, „dwustu gramów”) → jeden token liczby.
// Klucze bez polskich znaków; mianownik i dopełniacz/narzędnik (w tym „dwudziestoma”).
const n = (value: number, ...forms: string[]) => forms.map((f) => [f, value] as const);
const HUNDREDS = new Map([
  ...n(100, 'sto', 'stu'),
  ...n(200, 'dwiescie', 'dwustu'),
  ...n(300, 'trzysta', 'trzystu'),
  ...n(400, 'czterysta', 'czterystu'),
  ...n(500, 'piecset', 'pieciuset'),
  ...n(600, 'szescset', 'szesciuset'),
  ...n(700, 'siedemset', 'siedmiuset'),
  ...n(800, 'osiemset', 'osmiuset'),
  ...n(900, 'dziewiecset', 'dziewieciuset'),
]);
const TENS = new Map([
  ...n(20, 'dwadziescia', 'dwudziestu', 'dwudziestoma'),
  ...n(30, 'trzydziesci', 'trzydziestu', 'trzydziestoma'),
  ...n(40, 'czterdziesci', 'czterdziestu', 'czterdziestoma'),
  ...n(50, 'piecdziesiat', 'piecdziesieciu'),
  ...n(60, 'szescdziesiat', 'szescdziesieciu'),
  ...n(70, 'siedemdziesiat', 'siedemdziesieciu'),
  ...n(80, 'osiemdziesiat', 'osiemdziesieciu'),
  ...n(90, 'dziewiecdziesiat', 'dziewiecdziesieciu'),
]);
const TEENS = new Map([
  ...n(10, 'dziesiec', 'dziesieciu'),
  ...n(11, 'jedenascie', 'jedenastu'),
  ...n(12, 'dwanascie', 'dwunastu'),
  ...n(13, 'trzynascie', 'trzynastu'),
  ...n(14, 'czternascie', 'czternastu'),
  ...n(15, 'pietnascie', 'pietnastu'),
  ...n(16, 'szesnascie', 'szesnastu'),
  ...n(17, 'siedemnascie', 'siedemnastu'),
  ...n(18, 'osiemnascie', 'osiemnastu'),
  ...n(19, 'dziewietnascie', 'dziewietnastu'),
]);
const UNITS = new Map([
  ...n(1, 'jeden', 'jedna', 'jedno', 'jednego', 'jednej'),
  ...n(2, 'dwa', 'dwie', 'dwoch', 'dwu'),
  ...n(3, 'trzy', 'trzech'),
  ...n(4, 'cztery', 'czterech'),
  ...n(5, 'piec', 'pieciu'),
  ...n(6, 'szesc', 'szesciu'),
  ...n(7, 'siedem', 'siedmiu'),
  ...n(8, 'osiem', 'osmiu'),
  ...n(9, 'dziewiec', 'dziewieciu'),
]);
const THOUSAND = new Set(['tysiac', 'tysiaca', 'tysiace', 'tysiecy']);

/** Łączy kolejne słowa liczebnika złożonego w token liczby. Pojedyncze 1–10 zostają słowami (słownik parsera). */
export function mergeNumerals(tokens: Token[]): Token[] {
  const out: Token[] = [];
  for (let i = 0; i < tokens.length; ) {
    let j = i;
    let value = 0;
    const word = (k: number) => (tokens[k]?.type === 'word' ? tokens[k]!.key : '');
    if (THOUSAND.has(word(j))) {
      value += 1000;
      j++;
    }
    const h = HUNDREDS.get(word(j));
    if (h !== undefined) {
      value += h;
      j++;
    }
    const teen = TEENS.get(word(j));
    if (teen !== undefined) {
      value += teen;
      j++;
    } else {
      const t = TENS.get(word(j));
      if (t !== undefined) {
        value += t;
        j++;
      }
      // jedności tylko jako część liczebnika złożonego („dwadzieścia pięć”, „sto dwa”)
      const u = j > i ? UNITS.get(word(j)) : undefined;
      if (u !== undefined) {
        value += u;
        j++;
      }
    }
    const single = j === i + 1 && word(i) !== '' && TEENS.get(word(i)) === 10;
    if (j > i && !single) {
      const raw = tokens.slice(i, j).map((t) => t.raw).join(' ');
      out.push({ type: 'num', raw, key: String(value), value });
      i = j;
    } else {
      out.push(tokens[i]!);
      i++;
    }
  }
  return out;
}

export function tokensText(tokens: readonly Token[]): string {
  return tokens
    .map((t) => t.raw)
    .join(' ')
    .replace(/ ,/g, ',')
    .replace(/(\d)\.(\d)/g, '$1,$2');
}
