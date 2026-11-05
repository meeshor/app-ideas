// Podpowiedzi produktów/dań do wyboru w UI (zamiana dopasowania, dodawanie składnika).

import type { FoodDb } from './db.ts';
import { osaDistance } from './fuzzy.ts';
import type { Lexicon } from './lexicon.ts';
import { keyOf, normalizeBasic } from './text.ts';

export interface Suggestion {
  kind: 'food' | 'dish';
  id: string;
  name: string;
  score: number;
}

/** Wyszukiwanie po nazwach, aliasach i formach: prefiks > zawieranie > literówka. */
export function searchNames(db: FoodDb, lex: Lexicon, query: string, limit = 8, kinds: ('food' | 'dish')[] = ['food', 'dish']): Suggestion[] {
  const q = keyOf(query);
  const qRaw = normalizeBasic(query);
  if (!q) return [];
  const best = new Map<string, Suggestion>();
  const consider = (kind: 'food' | 'dish', id: string, score: number) => {
    if (!kinds.includes(kind)) return;
    const k = `${kind}:${id}`;
    const prev = best.get(k);
    if (!prev || score > prev.score) {
      const name = kind === 'food' ? db.foods.get(id)?.name : db.dishes.get(id)?.name;
      if (name) best.set(k, { kind, id, name, score });
    }
  };
  for (const list of lex.names.values()) {
    for (const e of list) {
      const text = e.keys.join(' ');
      let score = 0;
      if (text === q) score = 100;
      else if (text.startsWith(q)) score = 80 - Math.min(20, text.length - q.length);
      else if (text.includes(q)) score = 50 - Math.min(20, text.length - q.length);
      else if (q.length >= 4) {
        const d = osaDistance(text.slice(0, q.length + 1), q, 2);
        if (d <= 2) score = 30 - d * 10;
      }
      if (score > 0 && qRaw !== q && e.raw.join(' ').includes(qRaw)) score += 10; // zgodne polskie znaki
      if (score > 0) consider(e.kind, e.id, score + (e.isBase ? 5 : 0) + (e.user ? 3 : 0));
    }
  }
  return [...best.values()].sort((a, b) => b.score - a.score || a.name.localeCompare(b.name, 'pl')).slice(0, limit);
}
