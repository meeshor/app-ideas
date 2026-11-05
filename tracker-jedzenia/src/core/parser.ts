// Parser oparty na słowniku i regułach (bez AI). Deterministyczny: ten sam tekst + ta sama baza = ten sam wynik.
//
// Kroki (szczegóły i ograniczenia: docs/parser.md):
// 1. Normalizacja i tokenizacja (text.ts); klucze bez polskich znaków.
// 2. Skan od lewej: w każdym miejscu najpierw NAJDŁUŻSZE dopasowanie aliasu (także wielowyrazowego,
//    zawierającego „z”/„i”), dopiero potem separatory dzielą pozycje.
// 3. Przed nazwą: ilość (liczba/liczebnik), jednostka, rozmiar, modyfikator ilości.
// 4. Po nazwie: rozmiar, ilość z jednostką („ryż 150 g”), dodatki „z/ze/na X”, „bez X”.
// 5. Po separatorze: „i serem” (narzędnik) dokleja się jako dodatek, „bez masła” i „dużo masła”
//    modyfikują poprzednią pozycję.
// 6. Sygnatura dania: produkt główny (lub jego wariant) + dodatki → najlepiej pasujące danie.
// 7. Dopasowanie przybliżone (literówki) tylko, gdy nie ma dokładnego, z obniżoną pewnością.
// Osobiste definicje użytkownika wygrywają remisy (flaga `user` w leksykonie).

import { CONFIG } from './config.ts';
import { sameFamily, resolveFood, type FoodDb } from './db.ts';
import { osaDistance } from './fuzzy.ts';
import { buildLexicon, type Lexicon, type NameEntry } from './lexicon.ts';
import { tokenize, tokensText, type Token } from './text.ts';
import type { Dish, IngredientChange, Meal, ParsedItem, ParseResult, Parser, SizeKey, UnitKey } from './types.ts';

interface NameMatch {
  entry: NameEntry;
  len: number;
  confidence: number;
}

interface Attachment {
  foodId: string;
  qty: number | null;
  unit: UnitKey | null;
  size: SizeKey | null;
  factor: number;
  factorLabel: string | null;
  fragment: string;
  confidence: number;
  /** Dopisane po separatorze jako modyfikacja („, dużo masła”) — nie wpływa na wybór dania. */
  viaMod?: boolean;
}

interface Draft {
  start: number;
  main: NameMatch;
  qty: number | null;
  unit: UnitKey | null;
  size: SizeKey | null;
  factor: number;
  labels: string[];
  attachments: Attachment[];
  removals: { foodId: string; fragment: string }[];
  /** Niezrozumiane słowa wewnątrz pozycji („bułka z szynką wiejską” → „wiejską”). */
  unknown: string[];
  end: number;
}

interface Quantity {
  qty: number | null;
  unit: UnitKey | null;
  size: SizeKey | null;
  factor: number;
  factorLabel: string | null;
  negated: boolean;
  end: number;
}

export class RuleParser implements Parser {
  readonly id = 'rules-v1';
  private readonly lex: Lexicon;

  constructor(private readonly db: FoodDb, lexicon?: Lexicon) {
    this.lex = lexicon ?? buildLexicon(db);
  }

  parse(text: string): ParseResult {
    const tokens = mergeHalves(tokenize(text), this.lex);
    const items: ParsedItem[] = [];
    const unknown: string[] = [];
    let mealHint: Meal | undefined;
    let unknownBuf: Token[] = [];
    const flushUnknown = () => {
      if (unknownBuf.length) unknown.push(tokensText(unknownBuf));
      unknownBuf = [];
    };
    for (const t of tokens) {
      const meal = this.lex.mealWords.get(t.key);
      if (meal && !mealHint) mealHint = meal;
    }

    let pos = 0;
    while (pos < tokens.length) {
      const t = tokens[pos]!;
      if (this.isSeparator(t)) {
        flushUnknown();
        pos++;
        continue;
      }
      if (t.type === 'word' && this.lex.negations.has(t.key)) {
        // „bez cukru” bez poprzedniej pozycji — nie ma czego zmienić; pokazujemy jako niezrozumiane
        const name = this.matchName(tokens, pos + 1, true);
        const end = pos + 1 + (name?.len ?? 0);
        flushUnknown();
        unknown.push(tokensText(tokens.slice(pos, end)));
        pos = end;
        continue;
      }
      const draft = this.parseItem(tokens, pos);
      if (!draft) {
        // nic nie rozpoznano od tej pozycji — słowo nieznane albo wypełniacz
        if (t.type === 'word' && (this.lex.fillers.has(t.key) || this.lex.markers.has(t.key))) {
          flushUnknown();
        } else unknownBuf.push(t);
        pos++;
        continue;
      }
      flushUnknown();
      // kontynuacje po separatorze: „i serem”, „, bez masła”, „, dużo masła”
      let end = draft.end;
      for (;;) {
        const next = this.tryContinuation(tokens, end, draft);
        if (next === null) break;
        end = next;
      }
      draft.end = end;
      items.push(this.finalize(tokens, draft));
      unknown.push(...draft.unknown);
      pos = end;
    }
    flushUnknown();
    return mealHint ? { items, unknown, mealHint } : { items, unknown };
  }

  // ---------- rozpoznawanie słów ----------

  private isSeparator(t: Token): boolean {
    return t.type === 'sep' || (t.type === 'word' && this.lex.separators.has(t.key));
  }

  private matchAmount(tokens: Token[], pos: number): { end: number; multiplier: number; label: string } | null {
    for (const a of this.lex.amounts) {
      if (a.keys.every((k, i) => tokens[pos + i]?.type === 'word' && tokens[pos + i]!.key === k))
        return { end: pos + a.keys.length, multiplier: a.multiplier, label: a.label };
    }
    return null;
  }

  private numberAt(t: Token | undefined): number | null {
    if (!t) return null;
    if (t.type === 'num') return t.value;
    if (t.type === 'word') return this.lex.numbers.get(t.key) ?? null;
    return null;
  }

  /** Ilość / jednostka / rozmiar / modyfikator ilości / negacja przed nazwą. */
  private parseQuantity(tokens: Token[], pos: number): Quantity {
    const q: Quantity = { qty: null, unit: null, size: null, factor: 1, factorLabel: null, negated: false, end: pos };
    let p = pos;
    for (;;) {
      const t = tokens[p];
      if (!t || t.type === 'sep') break;
      const amount = this.matchAmount(tokens, p);
      if (amount) {
        q.factor *= amount.multiplier;
        q.factorLabel = amount.label;
        p = amount.end;
        continue;
      }
      const n = this.numberAt(t);
      if (n !== null) {
        // „1 1/2” → 1,5
        q.qty = q.qty !== null && q.unit === null && n < 1 ? q.qty + n : n;
        p++;
        continue;
      }
      if (t.type !== 'word') break;
      const unit = this.unitAt(tokens, p);
      if (unit) {
        q.unit = unit;
        if (q.qty === null) q.qty = 1;
        p++;
        continue;
      }
      const size = this.lex.sizes.get(t.key);
      if (size && !this.startsLongerName(tokens, p)) {
        q.size = size;
        p++;
        continue;
      }
      if (this.lex.negations.has(t.key)) {
        q.negated = true;
        p++;
        continue;
      }
      if (this.lex.fillers.has(t.key) && !this.lex.markers.has(t.key) && !this.exactName(tokens, p)) {
        p++;
        continue;
      }
      break;
    }
    q.end = p;
    return q;
  }

  /** Jednostka na pozycji — chyba że to w rzeczywistości nazwa produktu („pączki” ≠ „paczki”, „kawałek ciasta”). */
  private unitAt(tokens: Token[], pos: number): UnitKey | null {
    const t = tokens[pos];
    if (!t || t.type !== 'word') return null;
    const unit = this.lex.units.get(t.key);
    if (!unit) return null;
    const name = this.exactName(tokens, pos);
    if (name && (name.len > 1 || (!this.lex.unitRaw.has(t.raw) && name.confidence === CONFIG.parser.confidence.exact))) return null;
    return unit;
  }

  /** Czy od tej pozycji zaczyna się nazwa dłuższa niż jedno słowo (np. „kawałek ciasta” jako alias). */
  private startsLongerName(tokens: Token[], pos: number): boolean {
    const m = this.exactName(tokens, pos);
    return !!m && m.len > 1;
  }

  private exactName(tokens: Token[], pos: number, foodsOnly = false, maxLen = Infinity): NameMatch | null {
    const t = tokens[pos];
    if (!t || t.type !== 'word') return null;
    const list = this.lex.names.get(t.key);
    if (!list) return null;
    let best: NameMatch | null = null;
    let bestScore = -1;
    for (const e of list) {
      if (foodsOnly && e.kind !== 'food') continue;
      if (e.keys.length > maxLen) continue;
      if (best && e.keys.length < best.len) break; // posortowane malejąco wg długości
      if (!e.keys.every((k, i) => tokens[pos + i]?.type === 'word' && tokens[pos + i]!.key === k)) continue;
      const exactDiacritics = e.raw.every((r, i) => tokens[pos + i]!.raw === r);
      const score = (e.user ? 8 : 0) + (exactDiacritics ? 4 : 0) + (e.isBase ? 2 : 0) + (e.kind === 'dish' ? 1 : 0);
      if (!best || e.keys.length > best.len || score > bestScore || (score === bestScore && e.id < best.entry.id)) {
        best = {
          entry: e,
          len: e.keys.length,
          confidence: exactDiacritics ? CONFIG.parser.confidence.exact : CONFIG.parser.confidence.noDiacritics,
        };
        bestScore = score;
      }
    }
    return best;
  }

  private fuzzyName(tokens: Token[], pos: number, foodsOnly = false, minN = 1, longerThanId: string | null = null): NameMatch | null {
    const first = tokens[pos];
    if (!first || first.type !== 'word') return null;
    if (first.key.length < CONFIG.parser.fuzzyMinLength || this.lex.functionWords.has(first.key)) return null;
    let maxN = 0;
    while (maxN < 3 && tokens[pos + maxN]?.type === 'word' && !this.isSeparator(tokens[pos + maxN]!)) maxN++;
    for (let n = maxN; n >= minN; n--) {
      const words = tokens.slice(pos, pos + n);
      // dopasowanie wielowyrazowe nie może zaczynać się od dokładnego słowa funkcyjnego na końcu
      let best: { e: NameEntry; d: number } | null = null;
      for (const e of this.lex.byWordCount.get(n) ?? []) {
        if (foodsOnly && e.kind !== 'food') continue;
        const k0 = e.keys[0]!;
        const w0 = words[0]!.key;
        // dłuższe dopasowanie zamiast dokładnego: pierwsze słowo musi się zgadzać albo to ta sama pozycja
        if (longerThanId !== null ? k0 !== w0 && e.id !== longerThanId : k0[0] !== w0[0] && k0[1] !== w0[1]) continue; // szybki filtr: literówka rzadko psuje oba pierwsze znaki
        let total = 0;
        let ok = true;
        for (let i = 0; i < n; i++) {
          const a = words[i]!.key;
          const b = e.keys[i]!;
          if (a === b) continue;
          const max = CONFIG.parser.fuzzyMaxDistance(Math.min(a.length, b.length));
          if (max === 0 || this.lex.functionWords.has(a)) {
            ok = false;
            break;
          }
          const d = osaDistance(a, b, max);
          if (d > max) {
            ok = false;
            break;
          }
          total += d;
        }
        if (!ok || total === 0) continue;
        if (!best || total < best.d || (total === best.d && (Number(e.isBase) > Number(best.e.isBase) || (e.isBase === best.e.isBase && e.id < best.e.id)))) {
          best = { e, d: total };
        }
      }
      if (best) return { entry: best.e, len: n, confidence: CONFIG.parser.confidence.fuzzy };
    }
    return null;
  }

  private matchName(tokens: Token[], pos: number, foodsOnly = false): NameMatch | null {
    const exact = this.exactName(tokens, pos, foodsOnly);
    // literówka w dłuższej nazwie („bułka żytna”, „spagetti bolonese”) — dłuższe dopasowanie przybliżone wygrywa
    const fuzzy = this.fuzzyName(tokens, pos, foodsOnly, exact ? exact.len + 1 : 1, exact?.entry.id ?? null);
    if (exact && (!fuzzy || fuzzy.len <= exact.len)) return exact;
    return fuzzy ?? exact;
  }

  // ---------- pozycja ----------

  private parseItem(tokens: Token[], pos: number): Draft | null {
    const q = this.parseQuantity(tokens, pos);
    if (q.negated) return null; // „bez X” bez poprzedniej pozycji — nie ma czego modyfikować
    const name = this.matchName(tokens, q.end);
    if (!name) return null;
    let start = pos;
    while (start < q.end && tokens[start]?.type === 'word' && this.lex.fillers.has(tokens[start]!.key) && !this.lex.markers.has(tokens[start]!.key)) start++;
    const draft: Draft = {
      start,
      main: name,
      qty: q.qty,
      unit: q.unit,
      size: q.size,
      factor: q.factor,
      labels: [],
      attachments: [],
      removals: [],
      unknown: [],
      end: q.end + name.len,
    };
    if (q.size) draft.labels.push(this.sizeLabel(q.size));
    if (q.factorLabel) draft.labels.push(q.factorLabel);
    this.parsePost(tokens, draft);
    // Alias dania typu „bułka z szynką” mógł uciąć dalszy opis („… drobiową”, „… i ogórkiem”).
    // Próbujemy rozbioru „produkt + dodatki”; jeśli pochłania więcej tekstu, wygrywa (sygnatura znajdzie danie).
    if (name.entry.kind === 'dish' && name.entry.keys.some((k) => k === 'z' || k === 'ze') && name.len > 1) {
      const head = this.exactName(tokens, q.end, true, name.len - 1);
      if (head) {
        const alt: Draft = { ...draft, main: head, labels: [...draft.labels].slice(0, Number(!!q.size) + Number(!!q.factorLabel)), attachments: [], removals: [], unknown: [], end: q.end + head.len };
        this.parsePost(tokens, alt);
        if (alt.end > draft.end && alt.unknown.length <= draft.unknown.length) return alt;
      }
    }
    return draft;
  }

  private sizeLabel(s: SizeKey): string {
    return this.db.modifiers.sizes[s]?.label ?? s;
  }

  /** Część po nazwie: rozmiar, ilość z jednostką, dodatki „z X”, „bez X”. */
  private parsePost(tokens: Token[], d: Draft): void {
    let p = d.end;
    for (;;) {
      const t = tokens[p];
      if (!t || this.isSeparator(t)) break;
      if (t.type === 'word') {
        const size = this.lex.sizes.get(t.key);
        if (size && !d.size) {
          d.size = size;
          d.labels.push(this.sizeLabel(size));
          p++;
          continue;
        }
        if (this.lex.markers.has(t.key)) {
          const att = this.parseAttachment(tokens, p + 1);
          if (att) {
            d.attachments.push(att.att);
            p = att.end;
            continue;
          }
          // marker bez produktu: „na śniadanie”, „z grilla” — pomijamy razem z wypełniaczem;
          // w przeciwnym razie kończymy pozycję (dalsze słowa trafią do niezrozumianych)
          const nx = tokens[p + 1];
          if (nx?.type === 'word' && this.lex.fillers.has(nx.key) && !this.lex.markers.has(nx.key)) {
            p += 2;
            continue;
          }
          break;
        }
        if (this.lex.negations.has(t.key)) {
          const name = this.matchName(tokens, p + 1, true);
          if (name) {
            d.removals.push({ foodId: name.entry.id, fragment: tokensText(tokens.slice(p, p + 1 + name.len)) });
            p += 1 + name.len;
            continue;
          }
          break;
        }
        const amount = this.matchAmount(tokens, p);
        if (amount) {
          const name = this.matchName(tokens, amount.end, true);
          if (name) {
            // „kawa dużo mleka” — modyfikator ilości dodatku
            const att = this.parseAttachment(tokens, p);
            if (att) {
              d.attachments.push(att.att);
              p = att.end;
              continue;
            }
          }
          d.factor *= amount.multiplier;
          d.labels.push(amount.label);
          p = amount.end;
          continue;
        }
      }
      // ilość po nazwie: „ryż 150 g”, „jajka 2”
      const n = this.numberAt(t);
      if (n !== null || this.unitAt(tokens, p) !== null) {
        const q = this.parseQuantity(tokens, p);
        if (q.end > p && !this.matchName(tokens, q.end) && (q.qty !== null || q.unit !== null)) {
          if (d.qty === null || d.unit === null) {
            d.qty = q.qty ?? d.qty;
            d.unit = q.unit ?? d.unit;
          }
          p = q.end;
          continue;
        }
        break; // to początek nowej pozycji („kawa 2 jajka”)
      }
      if (t.type === 'word' && this.lex.fillers.has(t.key)) {
        p++;
        continue;
      }
      // nieznane słowo w środku pozycji, po którym pozycja się kontynuuje („z …”, „bez …”, rozmiar)
      const nx = tokens[p + 1];
      if (t.type === 'word' && !this.matchName(tokens, p) && nx?.type === 'word' &&
          (this.lex.markers.has(nx.key) || this.lex.negations.has(nx.key) || this.lex.sizes.has(nx.key))) {
        d.unknown.push(t.raw);
        p++;
        continue;
      }
      break;
    }
    d.end = p;
  }

  private parseAttachment(tokens: Token[], pos: number): { att: Attachment; end: number } | null {
    const q = this.parseQuantity(tokens, pos);
    if (q.negated) return null;
    const name = this.matchName(tokens, q.end, true);
    if (!name) return null;
    let end = q.end + name.len;
    let size = q.size;
    const t = tokens[end];
    if (t?.type === 'word' && this.lex.sizes.has(t.key) && !size) {
      size = this.lex.sizes.get(t.key)!;
      end++;
    }
    return {
      att: {
        foodId: name.entry.id,
        qty: q.qty,
        unit: q.unit,
        size,
        factor: q.factor,
        factorLabel: q.factorLabel,
        fragment: tokensText(tokens.slice(pos - (this.lex.markers.has(tokens[pos - 1]?.key ?? '') ? 1 : 0), end)),
        confidence: name.confidence,
      },
      end,
    };
  }

  /** Składniki (rodziny) obecne w pozycji — do decyzji, czy „dużo masła” modyfikuje poprzednią pozycję. */
  private draftFoodIds(d: Draft): string[] {
    const ids = d.attachments.map((a) => a.foodId);
    if (d.main.entry.kind === 'food') ids.push(d.main.entry.id);
    else ids.push(...(this.db.dishes.get(d.main.entry.id)?.ingredients.map((i) => i.foodId) ?? []));
    const sig = d.main.entry.kind === 'food' ? this.findSignatureDish(d.main.entry.id, d.attachments) : null;
    if (sig) ids.push(...sig.dish.ingredients.map((i) => i.foodId));
    return ids;
  }

  private tryContinuation(tokens: Token[], pos: number, d: Draft): number | null {
    const sep = tokens[pos];
    if (!sep || !this.isSeparator(sep)) return null;
    const p = pos + 1;
    const t = tokens[p];
    if (!t) return null;
    // „bułki z szynką, 2 sztuki” — sama ilość po przecinku dotyczy poprzedniej pozycji
    if (this.numberAt(t) !== null && d.qty === null) {
      const q = this.parseQuantity(tokens, p);
      const after = tokens[q.end];
      if (q.end > p && q.qty !== null && (!after || this.isSeparator(after)) && !this.matchName(tokens, q.end)) {
        d.qty = q.qty;
        if (q.unit && q.unit !== 'sztuka' && q.unit !== 'porcja') d.unit = q.unit;
        return q.end;
      }
    }
    if (t.type !== 'word') return null;
    // „, bez masła”
    if (this.lex.negations.has(t.key)) {
      const name = this.matchName(tokens, p + 1, true);
      if (!name) return null;
      d.removals.push({ foodId: name.entry.id, fragment: tokensText(tokens.slice(p, p + 1 + name.len)) });
      d.end = p + 1 + name.len;
      this.parsePost(tokens, d);
      return d.end;
    }
    // „, dużo masła” — jeśli masło jest w pozycji
    const amount = this.matchAmount(tokens, p);
    if (amount) {
      const name = this.matchName(tokens, amount.end, true);
      if (name && this.draftFoodIds(d).some((id) => sameFamily(this.db, id, name.entry.id))) {
        const att = this.parseAttachment(tokens, p);
        if (att) {
          att.att.viaMod = true;
          d.attachments.push(att.att);
          return att.end;
        }
      }
      return null;
    }
    // „i serem” — narzędnik po wcześniejszym „z …”
    const nameHasZ = d.main.entry.keys.some((k) => k === 'z' || k === 'ze');
    if ((d.attachments.length > 0 || nameHasZ) && this.numberAt(t) === null && this.unitAt(tokens, p) === null) {
      const name = this.matchName(tokens, p, true);
      if (name && name.entry.kind === 'food') {
        const lastRaw = tokens[p + name.len - 1]!.raw;
        const firstRaw = t.raw;
        const instr = CONFIG.parser.instrumentalEndings.some((e) => firstRaw.endsWith(e) || lastRaw.endsWith(e));
        if (instr) {
          const att = this.parseAttachment(tokens, p);
          if (att) {
            att.att.fragment = tokensText(tokens.slice(pos, att.end));
            d.attachments.push(att.att);
            return att.end;
          }
        }
      }
    }
    return null;
  }

  // ---------- składanie wyniku ----------

  /** Najlepsze danie pasujące do „<główny> z <dodatki>”: max liczba dopasowanych dodatków. */
  private findSignatureDish(mainId: string, atts: Attachment[]): { dish: Dish; used: Set<number> } | null {
    let best: { dish: Dish; used: Set<number>; user: boolean; idxSum: number } | null = null;
    for (const dish of this.db.dishes.values()) {
      if (dish.signature === false) continue;
      const mainIdx = dish.main ?? 0;
      const mainIng = dish.ingredients[mainIdx];
      if (!mainIng || !sameFamily(this.db, mainIng.foodId, mainId)) continue;
      const required = dish.ingredients.filter((ing, i) => i !== mainIdx && !ing.optional);
      if (required.length === 0) continue;
      const used = new Set<number>();
      let ok = true;
      for (const ing of required) {
        const idx = atts.findIndex((a, i) => !used.has(i) && !a.viaMod && sameFamily(this.db, a.foodId, ing.foodId));
        if (idx === -1) {
          ok = false;
          break;
        }
        used.add(idx);
      }
      if (!ok) continue;
      const user = (this.db.origin.get(`dish:${dish.id}`) ?? 'default') !== 'default';
      const idxSum = [...used].reduce((a, b) => a + b, 0);
      // remis: danie użytkownika, potem danie oparte na wcześniejszych dodatkach, potem id
      const better =
        !best ||
        used.size > best.used.size ||
        (used.size === best.used.size &&
          (user !== best.user ? user : idxSum !== best.idxSum ? idxSum < best.idxSum : dish.id < best.dish.id));
      if (better) best = { dish, used, user, idxSum };
    }
    return best ? { dish: best.dish, used: best.used } : null;
  }

  private finalize(tokens: Token[], d: Draft): ParsedItem {
    const changes: IngredientChange[] = [];
    const modifiers = [...d.labels];
    let kind = d.main.entry.kind;
    let matchedId = d.main.entry.id;
    let confidence = d.main.confidence;
    let ingredients = kind === 'dish' ? (this.db.dishes.get(matchedId)?.ingredients ?? []) : [];
    let remaining = d.attachments;

    if (kind === 'food') {
      const sig = this.findSignatureDish(matchedId, d.attachments);
      if (sig) {
        const dish = sig.dish;
        const mainIng = dish.ingredients[dish.main ?? 0]!;
        if (mainIng.foodId !== matchedId) changes.push({ op: 'variant', foodId: matchedId, fragment: this.db.foods.get(matchedId)?.name ?? matchedId });
        kind = 'dish';
        matchedId = dish.id;
        ingredients = dish.ingredients;
        // dodatki użyte przez sygnaturę: tylko wariant / ilość / mnożnik
        for (const i of sig.used) {
          const a = d.attachments[i]!;
          const ing = ingredients.find((x) => sameFamily(this.db, x.foodId, a.foodId));
          if (ing && ing.foodId !== a.foodId) changes.push({ op: 'variant', foodId: a.foodId, fragment: a.fragment });
          if (a.qty !== null) changes.push({ op: 'set', foodId: a.foodId, qty: a.qty, unit: a.unit, fragment: a.fragment });
          if (a.factor !== 1) {
            changes.push({ op: 'scale', foodId: a.foodId, factor: a.factor, fragment: a.fragment });
            modifiers.push(`${a.factorLabel ?? '×' + a.factor} ${this.foodName(a.foodId)}`);
          }
          confidence = Math.min(confidence, a.confidence);
        }
        remaining = d.attachments.filter((_, i) => !sig.used.has(i));
      }
    }

    for (const a of remaining) {
      confidence = Math.min(confidence, a.confidence);
      const ing = kind === 'dish' ? ingredients.find((x) => sameFamily(this.db, x.foodId, a.foodId)) : undefined;
      const already = changes.some((c) => c.op === 'add' && sameFamily(this.db, c.foodId, a.foodId));
      if (ing && !already) {
        if (ing.foodId !== a.foodId) changes.push({ op: 'variant', foodId: a.foodId, fragment: a.fragment });
        if (a.qty !== null) changes.push({ op: 'set', foodId: a.foodId, qty: a.qty, unit: a.unit, fragment: a.fragment });
        if (a.factor !== 1) {
          changes.push({ op: 'scale', foodId: a.foodId, factor: a.factor, fragment: a.fragment });
          modifiers.push(`${a.factorLabel ?? '×' + a.factor} ${this.foodName(a.foodId)}`);
        }
        continue;
      }
      const rf = resolveFood(this.db, a.foodId);
      const qty = a.qty ?? rf?.addon?.qty ?? 1;
      const unit = a.qty !== null ? a.unit : a.unit ?? rf?.addon?.unit ?? null;
      const add: IngredientChange = { op: 'add', foodId: a.foodId, qty, unit, size: a.size, fragment: a.fragment };
      if (a.factor !== 1) add.factor = a.factor;
      changes.push(add);
      modifiers.push(a.factor !== 1 ? `${a.factorLabel} ${this.foodName(a.foodId)}` : `+ ${this.foodName(a.foodId)}`);
    }

    for (const r of d.removals) {
      changes.push({ op: 'remove', foodId: r.foodId, fragment: r.fragment });
      modifiers.push(`bez: ${this.foodName(r.foodId)}`);
    }

    const item: ParsedItem = {
      kind,
      matchedId,
      quantity: d.qty ?? 1,
      unit: d.unit,
      size: d.size,
      modifiers,
      factor: d.factor,
      confidence,
      fragment: tokensText(tokens.slice(d.start, d.end).filter((t, i, arr) => !(i === arr.length - 1 && t.type === 'sep'))),
      changes,
    };
    return item;
  }

  private foodName(id: string): string {
    return this.db.foods.get(id)?.name ?? id;
  }
}

/** „2 i pół” → 2,5; „dwa i pół” → 2,5 (zanim „i” zostanie potraktowane jako separator). */
function mergeHalves(tokens: Token[], lex: Lexicon): Token[] {
  const out: Token[] = [];
  for (let i = 0; i < tokens.length; i++) {
    const t = tokens[i]!;
    const n = t.type === 'num' ? t.value : t.type === 'word' ? lex.numbers.get(t.key) : undefined;
    if (n !== undefined && n >= 1 && tokens[i + 1]?.key === 'i' && tokens[i + 2]?.key === 'pol') {
      const raw = `${t.raw} i ${tokens[i + 2]!.raw}`;
      out.push({ type: 'num', raw, key: raw, value: n + 0.5 });
      i += 2;
      continue;
    }
    out.push(t);
  }
  return out;
}
