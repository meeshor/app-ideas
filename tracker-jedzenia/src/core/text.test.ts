import { describe, expect, it } from 'vitest';
import { keyOf, parseNumber, stripDiacritics, tokenize, tokensText } from './text.ts';

describe('text', () => {
  it('usuwa polskie znaki', () => {
    expect(stripDiacritics('Zażółć gęślą jaźń')).toBe('Zazolc gesla jazn');
    expect(keyOf('  BUŁKĄ   z Szynką ')).toBe('bulka z szynka');
  });
  it('parsuje liczby', () => {
    expect(parseNumber('2')).toBe(2);
    expect(parseNumber('2,5')).toBe(2.5);
    expect(parseNumber('2.5')).toBe(2.5);
    expect(parseNumber('1/2')).toBe(0.5);
    expect(parseNumber('1/0')).toBeNull();
    expect(parseNumber('abc')).toBeNull();
  });
  it('tokenizuje separatory, jednostki sklejone i przecinek dziesiętny', () => {
    const t = tokenize('200g ryżu, 2,5 jajka + kawa');
    expect(t.map((x) => x.type)).toEqual(['num', 'word', 'word', 'sep', 'num', 'word', 'sep', 'word']);
    expect(t[4]).toMatchObject({ type: 'num', value: 2.5 });
    expect(tokensText(t)).toBe('200 g ryżu, 2,5 jajka, kawa');
  });
  it('obsługuje „2x”, „x2”, nowe linie, procenty i myślniki', () => {
    expect(tokenize('bułka x2').map((x) => x.raw)).toEqual(['bułka', '2']);
    expect(tokenize('2x jajko').map((x) => x.raw)).toEqual(['2', 'jajko']);
    expect(tokenize('mleko 2%').map((x) => x.raw)).toEqual(['mleko']);
    expect(tokenize('kawa\nherbata').map((x) => x.type)).toEqual(['word', 'sep', 'word']);
    expect(tokenize('hot-dog').map((x) => x.raw)).toEqual(['hot', 'dog']);
    expect(tokenize(' , ,')).toEqual([]);
  });
});
