import { describe, expect, it } from 'vitest';
import { inflectPhrase } from './inflect.ts';

const has = (phrase: string, ...forms: string[]) => {
  const out = inflectPhrase(phrase);
  for (const f of forms) expect(out, `${phrase} → ${f}`).toContain(f);
};

describe('inflect (reguły końcówek)', () => {
  it('rzeczowniki żeńskie na -a', () => {
    has('bułka', 'bułkę', 'bułki', 'bułką', 'bułek', 'bułkami');
    has('szynka', 'szynką', 'szynki', 'szynek');
    has('kawa', 'kawę', 'kawy', 'kawą');
    has('kasza', 'kaszy', 'kaszą', 'kaszę');
    has('herbata', 'herbatą', 'herbaty', 'herbacie');
  });
  it('nijakie na -o', () => {
    has('masło', 'masła', 'masłem');
    has('jajko', 'jajka', 'jajkiem', 'jajek');
    has('mleko', 'mleka', 'mlekiem');
  });
  it('męskie z ruchomym e i ó→o', () => {
    has('ogórek', 'ogórka', 'ogórkiem', 'ogórki', 'ogórków');
    has('twaróg', 'twarogu', 'twarogiem');
    has('ser', 'sera', 'serem', 'serze');
    has('chleb', 'chleba', 'chlebem');
    has('kurczak', 'kurczaka', 'kurczakiem');
  });
  it('liczba mnoga i zgadywana pojedyncza', () => {
    has('ziemniaki', 'ziemniaków', 'ziemniakami', 'ziemniak');
    has('frytki', 'frytek', 'frytkami', 'frytka');
    has('maliny', 'malin', 'malinami', 'malina');
  });
  it('rzeczownik + przymiotnik, z szykiem odwrotnym', () => {
    has('bułka żytnia', 'bułkę żytnią', 'bułki żytniej', 'bułką żytnią', 'żytnia bułka');
    has('ser żółty', 'serem żółtym', 'sera żółtego', 'żółty ser');
    has('czekolada gorzka', 'czekoladę gorzką', 'gorzkiej czekolady');
    has('serek wiejski', 'serka wiejskiego', 'serkiem wiejskim');
    has('mleko owsiane', 'mleka owsianego', 'mlekiem owsianym');
  });
  it('fraza z przyimkiem odmienia tylko początek', () => {
    has('tuńczyk w sosie własnym', 'tuńczyka w sosie własnym', 'tuńczykiem w sosie własnym');
    expect(inflectPhrase('bułka z szynką')).toContain('bułkę z szynką');
  });
  it('nazwy-przymiotniki', () => {
    has('pomidorowa', 'pomidorowej', 'pomidorową');
    has('schabowy', 'schabowego', 'schabowym');
  });
  it('słowa nieodmienne zostają', () => {
    expect(inflectPhrase('kiwi')).toEqual(['kiwi']);
  });
});
