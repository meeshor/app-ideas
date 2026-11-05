// Źródło danych startowych: dania złożone („przepisy”) z domyślnym składem.
// d(id, nazwa, składniki, opcje); składnik: [foodId, ilość, jednostka, opcjonalny?].
// Składnik opcjonalny = domyślny, który użytkownik może wyłączyć („bez masła”).
//
// Sygnatura dania = składnik główny + nieopcjonalne dodatki. Dzięki niej „bułkę żytnią z szynką”
// parser rozpozna jako „bułkę z szynką” z podmienioną bułką — aliasów z „z …” nie trzeba wpisywać.
// Składy to typowe „domowe” proporcje (do strojenia), verified: false.

import type { Dish } from '../src/core/types.ts';

type Ing = [string, number, string, boolean?];
interface Opts {
  aliases?: string[];
  forms?: string[];
  main?: number;
  sizeMode?: 'main' | 'all';
  signature?: boolean;
}

const SRC = 'typowy skład domowy (szacunek, do strojenia)';
const out: Dish[] = [];

function d(id: string, name: string, ings: Ing[], o: Opts = {}) {
  const dish: Dish = {
    id,
    name,
    ingredients: ings.map(([foodId, qty, unit, optional]) => (optional ? { foodId, qty, unit, optional: true } : { foodId, qty, unit })),
    aliases: o.aliases ?? [],
    category: 'danie',
    source: SRC,
    verified: false,
  };
  if (o.forms) dish.forms = o.forms;
  if (o.main !== undefined) dish.main = o.main;
  if (o.sizeMode) dish.sizeMode = o.sizeMode;
  if (o.signature === false) dish.signature = false;
  out.push(dish);
}

// --- kanapki i pieczywo ---
d('bulka-z-szynka', 'bułka z szynką', [['bulka', 1, 'sztuka'], ['szynka', 2, 'plaster'], ['maslo', 5, 'g', true]]);
d('bulka-z-serem', 'bułka z serem', [['bulka', 1, 'sztuka'], ['ser-zolty', 2, 'plaster'], ['maslo', 5, 'g', true]]);
d('bulka-z-szynka-i-serem', 'bułka z szynką i serem', [['bulka', 1, 'sztuka'], ['szynka', 2, 'plaster'], ['ser-zolty', 1, 'plaster'], ['maslo', 5, 'g', true]]);
d('bulka-z-maslem', 'bułka z masłem', [['bulka', 1, 'sztuka'], ['maslo', 7, 'g']]);
d('bulka-z-dzemem', 'bułka z dżemem', [['bulka', 1, 'sztuka'], ['dzem', 20, 'g'], ['maslo', 5, 'g', true]]);
d('bulka-z-twarogiem', 'bułka z twarożkiem', [['bulka', 1, 'sztuka'], ['twarog', 50, 'g'], ['maslo', 5, 'g', true]]);
d('kanapka', 'kanapka', [['chleb', 1, 'kromka'], ['maslo', 5, 'g', true]], {
  aliases: ['kanapeczka', 'kromka z masłem', 'chleb z masłem'],
  forms: ['kanapeczkę', 'kanapeczki', 'kanapeczek', 'kromkę z masłem', 'kromki z masłem'],
});
d('kanapka-z-szynka', 'kanapka z szynką', [['chleb', 1, 'kromka'], ['szynka', 1, 'plaster'], ['maslo', 5, 'g', true]], { signature: false });
d('tost', 'tost z szynką i serem', [['chleb-tostowy', 2, 'kromka'], ['szynka', 1, 'plaster'], ['ser-zolty', 1, 'plaster']], {
  aliases: ['tost', 'tosty', 'tost z serem', 'tosty z szynką i serem', 'tost z serem i szynką'],
  forms: ['tostem', 'tosta', 'tostów', 'tostami'],
  signature: false,
});
d('hot-dog', 'hot dog', [['bulka', 1, 'sztuka'], ['parowka', 1, 'sztuka'], ['keczup', 15, 'g', true]], { aliases: ['hotdog', 'hot doga', 'hot dogi'] });
d('wrap', 'wrap z kurczakiem', [['tortilla', 1, 'sztuka'], ['kurczak', 80, 'g'], ['salata', 20, 'g'], ['pomidor', 50, 'g'], ['sos-czosnkowy', 15, 'g', true]], {
  aliases: ['wrap', 'tortilla z kurczakiem', 'tortilla z kurczakiem i warzywami'],
  forms: ['wrapa', 'wrapem', 'wrapy'],
});

// --- śniadania ---
d('jajecznica', 'jajecznica', [['jajko', 3, 'sztuka'], ['maslo', 10, 'g', true]], {
  aliases: ['jajeczniczka', 'jajecznica z 3 jajek', 'jajecznica na maśle'],
  forms: ['jajeczniczkę', 'jajeczniczki'],
});
d('jajecznica-na-boczku', 'jajecznica na boczku', [['jajko', 3, 'sztuka'], ['boczek', 30, 'g'], ['maslo', 5, 'g', true]], { signature: false });
d('jajko-sadzone', 'jajko sadzone', [['jajko', 1, 'sztuka'], ['olej', 5, 'g', true]], { aliases: ['jajka sadzone', 'sadzone', 'jajo sadzone'], forms: ['jajek sadzonych', 'jajkiem sadzonym'] });
d('omlet', 'omlet', [['jajko', 3, 'sztuka'], ['mleko', 30, 'ml'], ['maslo', 5, 'g', true]], { aliases: ['omlecik', 'frittata'], forms: ['omleta', 'omletem', 'omlety', 'omlecika'] });
d('owsianka', 'owsianka', [['platki-owsiane', 50, 'g'], ['mleko', 200, 'ml']], { aliases: ['owsianka na mleku', 'porridge', 'owsianeczka'], forms: ['owsiankę', 'owsianki', 'owsianką'] });
d('owsianka-na-wodzie', 'owsianka na wodzie', [['platki-owsiane', 50, 'g'], ['woda', 200, 'ml']], { signature: false });
d('platki-z-mlekiem', 'płatki z mlekiem', [['platki-kukurydziane', 40, 'g'], ['mleko', 200, 'ml']], { aliases: ['płatki śniadaniowe z mlekiem'] });
d('jogurt-z-musli', 'jogurt z musli', [['jogurt-naturalny', 150, 'g'], ['musli', 40, 'g']], { aliases: ['jogurt z granolą', 'jogurt z płatkami'] });
d('twarozek-ze-szczypiorkiem', 'twarożek ze szczypiorkiem', [['twarog', 100, 'g'], ['szczypiorek', 5, 'g'], ['smietana', 15, 'g', true]], { aliases: ['twarożek z rzodkiewką', 'gzik'] });
d('nalesniki-z-serem', 'naleśniki z serem', [['nalesnik', 2, 'sztuka'], ['twarog', 80, 'g'], ['cukier', 5, 'g', true]], { aliases: ['naleśniki z twarogiem', 'naleśnik z serem'] });
d('nalesniki-z-dzemem', 'naleśniki z dżemem', [['nalesnik', 2, 'sztuka'], ['dzem', 40, 'g']], { aliases: ['naleśnik z dżemem', 'naleśniki z konfiturą'] });
d('nalesniki-z-nutella', 'naleśniki z nutellą', [['nalesnik', 2, 'sztuka'], ['krem-czekoladowy', 30, 'g']], { aliases: ['naleśnik z nutellą', 'naleśniki z kremem czekoladowym'] });
d('placki-ze-smietana', 'placki ziemniaczane ze śmietaną', [['placki-ziemniaczane', 3, 'sztuka'], ['smietana', 30, 'g']], { aliases: ['placki ze śmietaną'] });

// --- napoje ---
d('kawa-z-mlekiem', 'kawa z mlekiem', [['kawa', 220, 'ml'], ['mleko', 30, 'ml']], { aliases: ['biała kawa', 'kawa biała'], forms: ['białą kawę', 'białej kawy'], sizeMode: 'all' });
d('kawa-z-mlekiem-i-cukrem', 'kawa z mlekiem i cukrem', [['kawa', 220, 'ml'], ['mleko', 30, 'ml'], ['cukier', 5, 'g']], { sizeMode: 'all' });
d('herbata-z-cukrem', 'herbata z cukrem', [['herbata', 250, 'ml'], ['cukier', 5, 'g']], { aliases: ['herbata słodzona'], sizeMode: 'all' });
d('herbata-z-cytryna', 'herbata z cytryną', [['herbata', 250, 'ml'], ['cytryna', 1, 'plaster']]);
d('kakao', 'kakao domowe', [['mleko', 250, 'ml'], ['kakao-proszek', 5, 'g'], ['cukier', 10, 'g', true]], { aliases: ['kakao z cukrem'], signature: false });

// --- obiady ---
d('schabowy-z-ziemniakami', 'schabowy z ziemniakami', [['kotlet-schabowy', 1, 'sztuka'], ['ziemniaki', 200, 'g']], { aliases: ['kotlet z ziemniakami', 'obiad schabowy'], sizeMode: 'main' });
d('schabowy-z-ziemniakami-i-kapusta', 'schabowy z ziemniakami i kapustą', [['kotlet-schabowy', 1, 'sztuka'], ['ziemniaki', 200, 'g'], ['kapusta', 150, 'g']], {});
d('mielony-z-ziemniakami', 'mielony z ziemniakami', [['kotlet-mielony', 1, 'sztuka'], ['ziemniaki', 200, 'g']], { aliases: ['kotlet mielony z ziemniakami i mizerią'] });
d('kurczak-z-ryzem', 'kurczak z ryżem', [['kurczak', 150, 'g'], ['ryz', 150, 'g']], { aliases: ['pierś z kurczaka z ryżem', 'ryż z kurczakiem'] });
d('kurczak-z-ryzem-i-brokulami', 'kurczak z ryżem i brokułami', [['kurczak', 150, 'g'], ['ryz', 150, 'g'], ['brokul', 100, 'g']], { aliases: ['kurczak z ryżem i warzywami'] });
d('kurczak-z-frytkami', 'kurczak z frytkami', [['kurczak', 150, 'g'], ['frytki', 115, 'g'], ['surowka', 100, 'g', true]], { aliases: ['kotlet z frytkami'] });
d('spaghetti-bolognese', 'spaghetti bolognese', [['makaron', 200, 'g'], ['sos-bolognese', 150, 'g'], ['parmezan', 5, 'g', true]], {
  aliases: ['spaghetti z sosem bolognese', 'spagetti', 'makaron z sosem mięsnym', 'makaron bolognese', 'spaghetti bolońskie'],
  sizeMode: 'all',
  signature: false,
});
d('makaron-z-serem', 'makaron z serem', [['makaron', 200, 'g'], ['twarog', 80, 'g'], ['cukier', 10, 'g', true]], { aliases: ['makaron z twarogiem'], sizeMode: 'all' });
d('pierogi-ze-skwarkami', 'pierogi ze skwarkami', [['pierogi', 6, 'sztuka'], ['boczek', 20, 'g']], { aliases: ['pierogi z cebulką', 'pierogi okraszone'] });
d('mizeria', 'mizeria', [['ogorek', 150, 'g'], ['smietana', 30, 'g']], { aliases: ['ogórki ze śmietaną'], forms: ['mizerią', 'mizerii', 'mizerię'], signature: false });
d('salatka', 'sałatka', [['salata', 60, 'g'], ['pomidor', 80, 'g'], ['ogorek', 60, 'g'], ['oliwa', 10, 'g', true]], { aliases: ['sałatka warzywna', 'sałatka z warzyw', 'miska sałatki'], forms: ['sałatkę', 'sałatki', 'sałatką'], sizeMode: 'all', signature: false });
d('ryz-z-jablkami', 'ryż z jabłkami', [['ryz', 200, 'g'], ['jablko', 1, 'sztuka'], ['cukier', 10, 'g', true]], { sizeMode: 'all' });
d('kasza-z-sosem', 'kasza z gulaszem', [['kasza-gryczana', 150, 'g'], ['gulasz', 200, 'g']], { aliases: ['gulasz z kaszą', 'kasza z sosem'] });

// --- zupy z dodatkami ---
d('pomidorowa-z-makaronem', 'pomidorowa z makaronem', [['zupa-pomidorowa', 300, 'g'], ['makaron', 60, 'g']], { aliases: ['zupa pomidorowa z makaronem'], sizeMode: 'all' });
d('pomidorowa-z-ryzem', 'pomidorowa z ryżem', [['zupa-pomidorowa', 300, 'g'], ['ryz', 60, 'g']], { aliases: ['zupa pomidorowa z ryżem'], sizeMode: 'all' });
d('rosol-z-makaronem', 'rosół z makaronem', [['rosol', 300, 'g'], ['makaron', 60, 'g']], { aliases: ['rosół z makaronem nitki'], sizeMode: 'all' });
d('zurek-z-jajkiem', 'żurek z jajkiem', [['zurek', 300, 'g'], ['jajko', 1, 'sztuka'], ['kielbasa', 40, 'g', true]], { aliases: ['żurek z jajkiem i kiełbasą', 'żur z jajkiem'], sizeMode: 'all' });
d('barszcz-z-uszkami', 'barszcz z uszkami', [['barszcz', 250, 'g'], ['uszka', 80, 'g']], { aliases: ['barszcz czerwony z uszkami'], sizeMode: 'all' });
d('barszcz-z-krokietem', 'barszcz z krokietem', [['barszcz', 250, 'g'], ['nalesnik', 1, 'sztuka'], ['kapusta-kiszona', 40, 'g'], ['olej', 10, 'g']], { aliases: ['krokiet z barszczem', 'krokiet'], forms: ['krokieta', 'krokietem', 'krokiety'], signature: false });

export const DISHES = out;
