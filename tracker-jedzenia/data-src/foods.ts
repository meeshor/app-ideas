// Źródło danych startowych: produkty i warianty.
// Zapis zwięzły: f(id, nazwa, [kcal, węglowodany, białko, tłuszcz] na 100 g, opcje).
// `npm run data` generuje z tego data/foods.json (z formami odmiany).
//
// UCZCIWIE O LICZBACH: wartości to przybliżenia typowych pozycji z tabel składu żywności
// (NIZP-PZH, USDA FoodData Central) z pamięci autora danych, zaokrąglone. Żadna nie została
// sprawdzona z tabelą w trakcie tej sesji → wszędzie verified: false. Masy porcji to typowe
// wartości „kuchenne” (do strojenia). Dla mięs i kasz podajemy wartości PO przygotowaniu
// (tak ludzie zwykle opisują porcję na talerzu) — zaznaczone w `source`.

import type { Food } from '../src/core/types.ts';

type M = [number, number, number, number];
interface Opts {
  parent?: string;
  aliases?: string[];
  forms?: string[];
  portions?: Record<string, number>;
  def?: string;
  sizes?: [number, number, number];
  addon?: [number, string];
  density?: number;
  source?: string;
}

const SRC = 'przybliżone; typowe wartości z tabel składu (NIZP-PZH / USDA), niezweryfikowane';
const out: Food[] = [];
let category = '';

function cat(name: string) {
  category = name;
}

function f(id: string, name: string, m: M | null, o: Opts = {}) {
  const food: Food = { id, name };
  if (o.parent) food.parentId = o.parent;
  if (m) food.per100 = { kcal: m[0], carbs: m[1], protein: m[2], fat: m[3] };
  if (o.portions) food.portions = o.portions;
  if (o.def) food.defaultPortion = o.def;
  if (o.sizes) food.sizes = { small: o.sizes[0], standard: o.sizes[1], large: o.sizes[2] };
  if (o.addon) food.addon = { qty: o.addon[0], unit: o.addon[1] };
  if (o.density) food.density = o.density;
  food.aliases = o.aliases ?? [];
  if (o.forms) food.forms = o.forms;
  food.category = category;
  food.source = o.source ?? SRC;
  food.verified = false;
  out.push(food);
}

// ---------------- Pieczywo ----------------
cat('pieczywo');
f('bulka', 'bułka pszenna', [290, 57, 9, 2.5], {
  aliases: ['bułka', 'kajzerka', 'bułeczka', 'bułka zwykła'],
  forms: ['bułeczkę', 'bułeczki', 'bułeczką', 'bułeczek', 'kajzerkę', 'kajzerki', 'kajzerką', 'kajzerek'],
  portions: { sztuka: 60 }, def: 'sztuka', sizes: [45, 60, 80],
});
f('bulka-zytnia', 'bułka żytnia', [250, 48, 7.5, 2.5], { parent: 'bulka', aliases: ['bułka razowa'] });
f('bulka-grahamka', 'bułka grahamka', [260, 50, 9.5, 2.5], { parent: 'bulka', aliases: ['grahamka', 'bułka graham'] });
f('bulka-pelnoziarnista', 'bułka pełnoziarnista', [255, 46, 10, 3.5], { parent: 'bulka', aliases: ['bułka ziarnista', 'bułka wieloziarnista'] });
f('bulka-maslana', 'bułka maślana', [330, 55, 8.5, 8], { parent: 'bulka', aliases: ['bułka słodka'] });
f('chleb', 'chleb pszenny', [245, 50, 7.5, 1.5], {
  aliases: ['chleb', 'chleb mieszany', 'chleb biały', 'chlebek', 'pieczywo'],
  forms: ['chlebka', 'chlebkiem', 'chlebek', 'chlebku'],
  portions: { kromka: 35, kawalek: 50, sztuka: 35 }, def: 'kromka', sizes: [25, 35, 50],
});
f('chleb-zytni', 'chleb żytni', [230, 48, 6, 1.5], { parent: 'chleb' });
f('chleb-razowy', 'chleb razowy', [220, 45, 6, 1.6], { parent: 'chleb', aliases: ['razowiec'] });
f('chleb-pelnoziarnisty', 'chleb pełnoziarnisty', [240, 42, 9, 3.5], { parent: 'chleb', aliases: ['chleb ziarnisty', 'chleb wieloziarnisty'] });
f('chleb-tostowy', 'chleb tostowy', [265, 48, 8, 4], { parent: 'chleb', aliases: ['tostowy'], portions: { kromka: 25, sztuka: 25 }, sizes: [20, 25, 30] });
f('bagietka', 'bagietka', [270, 55, 9, 1.5], { portions: { kawalek: 50, sztuka: 250, kromka: 20 }, def: 'kawalek' });
f('croissant', 'croissant', [406, 45, 8, 21], { aliases: ['rogalik', 'rogal', 'croissanta'], forms: ['rogalika', 'rogalikiem', 'rogaliki', 'rogalików'], portions: { sztuka: 60 }, def: 'sztuka', sizes: [40, 60, 80] });
f('wafle-ryzowe', 'wafel ryżowy', [390, 81, 8, 3], { aliases: ['wafle ryżowe', 'wafelek ryżowy'], portions: { sztuka: 9 }, def: 'sztuka' });
f('paczek', 'pączek', [400, 48, 6, 20], { portions: { sztuka: 70 }, def: 'sztuka', sizes: [50, 70, 100] });
f('drozdzowka', 'drożdżówka', [330, 52, 7, 10], { portions: { sztuka: 90 }, def: 'sztuka', sizes: [60, 90, 130] });
f('tortilla', 'tortilla', [300, 50, 8, 7], { aliases: ['placek tortilla', 'tortille'], forms: ['tortillę', 'tortilli', 'tortillą'], portions: { sztuka: 60 }, def: 'sztuka' });
f('nalesnik', 'naleśnik', [210, 28, 7, 8], { source: SRC + '; naleśnik bez nadzienia', portions: { sztuka: 60 }, def: 'sztuka' });

// ---------------- Nabiał i jajka ----------------
cat('nabiał');
f('maslo', 'masło', [735, 0.7, 0.7, 82.5], { aliases: ['masełko'], forms: ['masełkiem', 'masełka'], portions: { lyzeczka: 5, lyzka: 12, plaster: 5, kostka: 200 }, def: 'lyzeczka', addon: [5, 'g'] });
f('margaryna', 'margaryna', [535, 0.5, 0.2, 60], { portions: { lyzeczka: 5, lyzka: 12 }, def: 'lyzeczka', addon: [5, 'g'] });
f('mleko', 'mleko', [50, 4.8, 3.4, 2], { source: SRC + '; mleko 2%', aliases: ['mleko krowie'], forms: ['mlekiem', 'mleka', 'mleku'], portions: { szklanka: 250, kubek: 250, lyzka: 15 }, def: 'szklanka', density: 1.03, addon: [30, 'ml'] });
f('mleko-pelne', 'mleko pełne', [61, 4.7, 3.2, 3.2], { parent: 'mleko', source: SRC + '; mleko 3,2%', aliases: ['mleko tłuste', 'mleko pełnotłuste'] });
f('mleko-chude', 'mleko chude', [36, 4.9, 3.4, 0.5], { parent: 'mleko', source: SRC + '; mleko 0,5%', aliases: ['mleko odtłuszczone'] });
f('mleko-owsiane', 'mleko owsiane', [45, 7, 0.5, 1.5], { parent: 'mleko', aliases: ['napój owsiany'] });
f('mleko-sojowe', 'mleko sojowe', [40, 2.5, 3.3, 1.8], { parent: 'mleko', aliases: ['napój sojowy'] });
f('jogurt-naturalny', 'jogurt naturalny', [60, 6, 4.3, 2], { aliases: ['jogurt'], portions: { kubek: 150, lyzka: 20, opakowanie: 150 }, def: 'kubek', addon: [2, 'lyzka'] });
f('jogurt-grecki', 'jogurt grecki', [130, 4, 3.5, 10], { parent: 'jogurt-naturalny' });
f('jogurt-owocowy', 'jogurt owocowy', [95, 14, 3.5, 2.5], { parent: 'jogurt-naturalny', aliases: ['jogurt truskawkowy', 'jogurt słodki'] });
f('skyr', 'skyr', [63, 4, 11, 0.2], { aliases: ['skyr naturalny'], portions: { kubek: 150 }, def: 'kubek' });
f('kefir', 'kefir', [50, 4.5, 3.4, 2], { portions: { szklanka: 250, butelka: 400, kubek: 250 }, def: 'szklanka', density: 1.03 });
f('maslanka', 'maślanka', [38, 4.7, 3.4, 0.6], { portions: { szklanka: 250, butelka: 500 }, def: 'szklanka', density: 1.03 });
f('smietana', 'śmietana 18%', [185, 3.6, 2.5, 18], { aliases: ['śmietana', 'śmietanka', 'kwaśna śmietana'], forms: ['śmietanką', 'śmietanki'], portions: { lyzka: 15, lyzeczka: 5, kubek: 200 }, def: 'lyzka', addon: [2, 'lyzka'] });
f('smietana-12', 'śmietana 12%', [135, 3.9, 2.7, 12], { parent: 'smietana', aliases: ['śmietanka do kawy'] });
f('smietana-30', 'śmietana 30%', [290, 3.2, 2.2, 30], { parent: 'smietana', aliases: ['kremówka', 'śmietana kremówka', 'bita śmietana'] });
f('ser-zolty', 'ser żółty', [356, 2.2, 25, 27], { aliases: ['ser', 'gouda', 'ser gouda', 'ser edamski', 'ser królewski'], forms: ['serem', 'sera', 'serek żółty', 'serkiem żółtym'], portions: { plaster: 20, kawalek: 30, lyzka: 8 }, def: 'plaster', addon: [1, 'plaster'] });
f('mozzarella', 'mozzarella', [250, 2, 18, 19], { forms: ['mozzarellą', 'mozzarelli', 'mozarella', 'mozarellą'], portions: { kulka: 125, plaster: 20, kawalek: 30 }, def: 'plaster', addon: [2, 'plaster'] });
f('parmezan', 'parmezan', [392, 3, 35, 28], { forms: ['parmezanem', 'parmezanu'], portions: { lyzka: 7, lyzeczka: 3 }, def: 'lyzka', addon: [1, 'lyzka'] });
f('twarog', 'twaróg półtłusty', [133, 3.5, 18.7, 4.7], { aliases: ['twaróg', 'ser biały', 'twarożek', 'ser twarogowy'], forms: ['twarożkiem', 'twarożku', 'twarożka'], portions: { plaster: 30, lyzka: 25, kostka: 250, porcja: 100 }, def: 'porcja', addon: [50, 'g'] });
f('twarog-chudy', 'twaróg chudy', [99, 3.7, 19.8, 0.5], { parent: 'twarog', aliases: ['ser biały chudy'] });
f('twarog-tlusty', 'twaróg tłusty', [175, 3.5, 17.7, 10], { parent: 'twarog', aliases: ['ser biały tłusty'] });
f('serek-wiejski', 'serek wiejski', [97, 2, 11, 5], { aliases: ['ser wiejski', 'twarożek ziarnisty', 'serek ziarnisty'], portions: { kubek: 200, opakowanie: 200, lyzka: 25 }, def: 'kubek' });
f('serek-homogenizowany', 'serek homogenizowany', [165, 14, 12, 6.5], { aliases: ['serek', 'serek waniliowy', 'homogenizowany'], portions: { kubek: 150, opakowanie: 150 }, def: 'kubek' });
f('serek-topiony', 'serek topiony', [250, 6, 10, 21], { aliases: ['ser topiony', 'serek trójkącik'], portions: { sztuka: 17, plaster: 17 }, def: 'sztuka' });
f('serek-kanapkowy', 'serek kanapkowy', [250, 4, 6, 23], { aliases: ['serek śmietankowy', 'serek do smarowania', 'almette', 'philadelphia'], portions: { lyzka: 20, lyzeczka: 8 }, def: 'lyzka', addon: [1, 'lyzka'] });
f('feta', 'ser feta', [265, 4, 14, 21], { aliases: ['feta', 'ser typu feta', 'ser sałatkowy'], forms: ['fetą', 'fety'], portions: { kawalek: 30, kostka: 200, plaster: 30 }, def: 'kawalek', addon: [30, 'g'] });
f('ser-plesniowy', 'ser pleśniowy', [300, 0.5, 20, 24], { aliases: ['camembert', 'brie', 'ser z pleśnią', 'lazur'], portions: { kawalek: 30 }, def: 'kawalek', addon: [30, 'g'] });
f('jajko', 'jajko', [140, 0.7, 12.5, 9.7], {
  source: SRC + '; masa części jadalnej',
  aliases: ['jajo', 'jajeczko', 'jajko gotowane', 'jajko na twardo', 'jajko na miękko', 'jajko kurze'],
  forms: ['jaja', 'jaj', 'jajami', 'jajem', 'jajeczka', 'jajeczek', 'jajka na twardo', 'jajek na twardo', 'jajka na miękko', 'jajek na miękko', 'jajka gotowane', 'jajek gotowanych'],
  portions: { sztuka: 55 }, def: 'sztuka', sizes: [45, 55, 65], addon: [1, 'sztuka'],
});

// ---------------- Wędliny ----------------
cat('wędliny');
f('szynka', 'szynka', [115, 1.5, 19, 4], { source: SRC + '; szynka wieprzowa gotowana', aliases: ['szynka wieprzowa', 'szyneczka', 'szynka konserwowa'], forms: ['szyneczką', 'szyneczki'], portions: { plaster: 15, porcja: 50 }, def: 'plaster', addon: [2, 'plaster'] });
f('szynka-drobiowa', 'szynka drobiowa', [100, 2, 19, 2], { parent: 'szynka', aliases: ['szynka z indyka', 'szynka z kurczaka', 'wędlina drobiowa'] });
f('szynka-parmenska', 'szynka parmeńska', [250, 0.5, 26, 16], { parent: 'szynka', aliases: ['szynka dojrzewająca', 'prosciutto'], portions: { plaster: 10 } });
f('poledwica', 'polędwica', [105, 1, 20, 2.5], { aliases: ['polędwica sopocka', 'polędwica łososiowa'], portions: { plaster: 15 }, def: 'plaster', addon: [2, 'plaster'] });
f('kielbasa', 'kiełbasa', [270, 1.5, 15, 23], { source: SRC + '; kiełbasa typu śląska/zwyczajna', aliases: ['kiełbaska', 'kiełbasa śląska', 'kiełbasa zwyczajna', 'kiełbasa wiejska', 'kiełbasa podwawelska'], forms: ['kiełbaską', 'kiełbaski', 'kiełbasek'], portions: { kawalek: 100, plaster: 10, sztuka: 100 }, def: 'kawalek', addon: [50, 'g'] });
f('kielbasa-krakowska', 'kiełbasa krakowska', [250, 1, 21, 18], { parent: 'kielbasa', aliases: ['krakowska'] });
f('kabanos', 'kabanos', [420, 1, 25, 35], { aliases: ['kabanosy'], portions: { sztuka: 30 }, def: 'sztuka' });
f('parowka', 'parówka', [260, 2, 11, 23], { aliases: ['parówki', 'frankfurterka'], portions: { sztuka: 45 }, def: 'sztuka', addon: [1, 'sztuka'] });
f('salami', 'salami', [430, 1, 22, 37], { portions: { plaster: 8 }, def: 'plaster', addon: [3, 'plaster'] });
f('boczek', 'boczek', [400, 0.5, 15, 38], { source: SRC + '; boczek wędzony', aliases: ['bekon', 'boczek wędzony', 'skwarki'], forms: ['skwarkami', 'skwarek', 'bekonem', 'bekonu'], portions: { plaster: 15 }, def: 'plaster', addon: [2, 'plaster'] });
f('pasztet', 'pasztet', [280, 5, 12, 24], { portions: { plaster: 25, lyzka: 20 }, def: 'plaster', addon: [1, 'plaster'] });

// ---------------- Mięso i ryby ----------------
cat('mięso i ryby');
f('kurczak', 'pierś z kurczaka', [165, 0, 31, 3.6], {
  source: SRC + '; pieczona/grillowana, bez skóry',
  aliases: ['kurczak', 'filet z kurczaka', 'pierś kurczaka', 'kurczak grillowany', 'filet drobiowy', 'pierś drobiowa'],
  forms: ['piersią z kurczaka', 'piersi z kurczaka', 'piersią kurczaka', 'piersi kurczaka', 'piersią drobiową', 'piersi drobiowej', 'filetem z kurczaka', 'kurczakiem', 'kurczaka', 'kurczaku'],
  portions: { porcja: 150, sztuka: 150, kawalek: 100 }, def: 'porcja', addon: [100, 'g'],
});
f('kurczak-udko', 'udko z kurczaka', [215, 0, 24, 13], { source: SRC + '; pieczone, ze skórą, część jadalna', aliases: ['udko', 'udka', 'podudzie', 'noga z kurczaka', 'skrzydełko'], forms: ['udkiem', 'udek', 'skrzydełka', 'skrzydełek'], portions: { sztuka: 100 }, def: 'sztuka' });
f('kotlet-drobiowy', 'kotlet drobiowy panierowany', [230, 10, 20, 12], { aliases: ['kotlet z kurczaka', 'kotlet drobiowy', 'sznycel', 'nuggetsy'], portions: { sztuka: 130 }, def: 'sztuka', sizes: [100, 130, 180] });
f('indyk', 'pierś z indyka', [135, 0, 29, 2], { source: SRC + '; pieczona', aliases: ['indyk', 'filet z indyka'], forms: ['indykiem', 'indyka', 'piersią z indyka', 'piersi z indyka'], portions: { porcja: 150 }, def: 'porcja', addon: [100, 'g'] });
f('schab', 'schab pieczony', [180, 0, 28, 7], { aliases: ['schab', 'schabik', 'pieczeń wieprzowa'], portions: { plaster: 50, porcja: 120 }, def: 'porcja' });
f('kotlet-schabowy', 'kotlet schabowy', [270, 10, 22, 16], { source: SRC + '; panierowany, smażony', aliases: ['schabowy', 'schabowe', 'kotlet', 'kotlet panierowany'], forms: ['schabowego', 'schabowym', 'schabowych', 'kotletem', 'kotleta', 'kotlety'], portions: { sztuka: 150 }, def: 'sztuka', sizes: [110, 150, 220] });
f('kotlet-mielony', 'kotlet mielony', [270, 8, 16, 19], { aliases: ['mielony', 'mielone', 'klops', 'pulpet', 'pulpety'], forms: ['mielonego', 'mielonym', 'mielonych', 'klopsem', 'pulpetami', 'pulpetów'], portions: { sztuka: 110 }, def: 'sztuka', sizes: [80, 110, 150] });
f('karkowka', 'karkówka', [250, 0, 22, 18], { source: SRC + '; grillowana/pieczona', aliases: ['karkówka z grilla'], portions: { plaster: 120, porcja: 120 }, def: 'plaster' });
f('wolowina', 'wołowina', [200, 0, 28, 10], { source: SRC + '; duszona/pieczona, chuda', aliases: ['stek', 'polędwica wołowa', 'mięso wołowe'], forms: ['stekiem', 'steka', 'steki'], portions: { porcja: 120, sztuka: 200 }, def: 'porcja' });
f('mieso-mielone', 'mięso mielone', [250, 0, 17, 20], { source: SRC + '; wieprzowo-wołowe, smażone/duszone', aliases: ['mielone mięso', 'mięso'], forms: ['mięsem', 'mięsa', 'mięsie', 'mięsem mielonym'], portions: { porcja: 100, lyzka: 25 }, def: 'porcja', addon: [80, 'g'] });
f('losos', 'łosoś', [206, 0, 22, 13], { source: SRC + '; pieczony', aliases: ['łosoś pieczony', 'łosoś wędzony'], forms: ['łososia', 'łososiem', 'łososiu', 'łososie', 'łososi', 'łososia wędzonego', 'łososiem wędzonym'], portions: { porcja: 125, kawalek: 125, plaster: 20 }, def: 'porcja', addon: [50, 'g'] });
f('dorsz', 'dorsz', [105, 0, 23, 0.9], { source: SRC + '; pieczony', aliases: ['ryba', 'mintaj', 'filet rybny', 'morszczuk'], forms: ['rybą', 'ryby', 'rybę', 'mintaja', 'mintajem', 'morszczuka'], portions: { porcja: 150, kawalek: 120 }, def: 'porcja' });
f('ryba-panierowana', 'ryba panierowana', [220, 14, 15, 12], { aliases: ['paluszki rybne', 'filet rybny panierowany', 'ryba smażona'], portions: { porcja: 150, sztuka: 30 }, def: 'porcja' });
f('tunczyk', 'tuńczyk w sosie własnym', [110, 0, 25, 1], { aliases: ['tuńczyk'], forms: ['tuńczykiem', 'tuńczyka'], portions: { puszka: 120, lyzka: 20 }, def: 'puszka', addon: [60, 'g'] });
f('sledz', 'śledź w oleju', [250, 1, 15, 21], { aliases: ['śledź', 'śledzie', 'śledzik', 'matjas'], forms: ['śledzia', 'śledziem', 'śledzi', 'śledziami', 'śledzika', 'matjasa'], portions: { kawalek: 50, sztuka: 50 }, def: 'kawalek' });
f('makrela', 'makrela wędzona', [225, 0, 21, 15], { aliases: ['makrela'], portions: { porcja: 100, sztuka: 200 }, def: 'porcja' });

// ---------------- Zboża, ziemniaki, makaron ----------------
cat('zboża i ziemniaki');
f('ryz', 'ryż biały', [130, 28, 2.7, 0.3], { source: SRC + '; ugotowany', aliases: ['ryż', 'ryż gotowany', 'ryż jaśminowy', 'ryż basmati'], forms: ['ryżem', 'ryżu'], portions: { porcja: 150, szklanka: 180, torebka: 250, lyzka: 20 }, def: 'porcja', addon: [150, 'g'] });
f('ryz-brazowy', 'ryż brązowy', [112, 23, 2.6, 0.9], { parent: 'ryz', source: SRC + '; ugotowany', aliases: ['ryż pełnoziarnisty', 'ryż dziki'] });
f('makaron', 'makaron', [158, 31, 5.8, 0.9], { source: SRC + '; ugotowany', aliases: ['makaron pszenny', 'spaghetti', 'penne', 'świderki', 'kokardki', 'nitki', 'tagliatelle'], forms: ['makaronem', 'makaronu', 'świderkami', 'nitkami', 'kokardkami'], portions: { porcja: 180, talerz: 250, szklanka: 140 }, def: 'porcja', addon: [60, 'g'] });
f('makaron-pelnoziarnisty', 'makaron pełnoziarnisty', [124, 25, 5.3, 0.5], { parent: 'makaron', source: SRC + '; ugotowany', aliases: ['makaron razowy'] });
f('kasza-gryczana', 'kasza gryczana', [92, 20, 3.4, 0.6], { source: SRC + '; ugotowana', aliases: ['gryczana', 'kasza', 'gryka'], forms: ['kaszą', 'kaszy', 'kaszę', 'gryczaną'], portions: { porcja: 150, torebka: 250, szklanka: 170 }, def: 'porcja', addon: [150, 'g'] });
f('kasza-jaglana', 'kasza jaglana', [119, 24, 3.5, 1], { parent: 'kasza-gryczana', source: SRC + '; ugotowana', aliases: ['jaglanka', 'jaglana'] });
f('kasza-peczak', 'kasza jęczmienna', [123, 28, 2.3, 0.4], { parent: 'kasza-gryczana', source: SRC + '; ugotowana', aliases: ['pęczak', 'kasza pęczak', 'kasza perłowa', 'kasza bulgur', 'bulgur'] });
f('kasza-manna', 'kasza manna', [360, 75, 10, 1], { source: SRC + '; sucha', aliases: ['manna', 'kaszka manna', 'semolina'], portions: { lyzka: 12, porcja: 40 }, def: 'lyzka' });
f('kuskus', 'kuskus', [112, 23, 3.8, 0.2], { source: SRC + '; ugotowany', aliases: ['kus kus', 'cous cous'], forms: ['kuskusem', 'kuskusu'], portions: { porcja: 150 }, def: 'porcja', addon: [150, 'g'] });
f('komosa', 'komosa ryżowa', [120, 21, 4.4, 1.9], { source: SRC + '; ugotowana', aliases: ['quinoa', 'kinoa'], portions: { porcja: 150 }, def: 'porcja', addon: [150, 'g'] });
f('platki-owsiane', 'płatki owsiane', [370, 60, 13, 7], { source: SRC + '; suche', aliases: ['owsiane', 'płatki górskie', 'płatki owsiane górskie'], portions: { lyzka: 10, szklanka: 90, garsc: 30, porcja: 50 }, def: 'porcja' });
f('musli', 'musli', [370, 65, 9, 7], { aliases: ['muesli', 'granola', 'musli z owocami'], portions: { porcja: 50, garsc: 30, lyzka: 12, szklanka: 100 }, def: 'porcja', addon: [40, 'g'] });
f('platki-kukurydziane', 'płatki kukurydziane', [375, 84, 7, 1], { aliases: ['płatki', 'corn flakes', 'płatki śniadaniowe', 'cini minis', 'płatki czekoladowe'], portions: { porcja: 40, miska: 40, garsc: 20, szklanka: 30 }, def: 'porcja' });
f('ziemniaki', 'ziemniaki gotowane', [86, 20, 1.9, 0.1], { aliases: ['ziemniaki', 'ziemniak', 'kartofle', 'kartofel', 'ziemniaczki', 'młode ziemniaki'], forms: ['ziemniaczkami', 'ziemniaczków', 'kartoflami', 'kartofli', 'ziemniakami', 'ziemniaków'], portions: { sztuka: 100, porcja: 200, talerz: 300, lyzka: 40 }, def: 'porcja', sizes: [150, 200, 300], addon: [200, 'g'] });
f('puree', 'puree ziemniaczane', [106, 15, 2, 4.2], { parent: 'ziemniaki', aliases: ['puree', 'purée', 'ziemniaki tłuczone', 'tłuczone ziemniaki'] });
f('ziemniaki-pieczone', 'ziemniaki pieczone', [140, 22, 2.5, 4.5], { parent: 'ziemniaki', aliases: ['ziemniaki z piekarnika', 'łódeczki ziemniaczane', 'talarki'] });
f('frytki', 'frytki', [312, 41, 3.4, 15], { aliases: ['frytka'], portions: { porcja: 115, garsc: 50 }, def: 'porcja', sizes: [80, 115, 155], addon: [115, 'g'] });
f('kopytka', 'kopytka', [160, 32, 4, 1.5], { aliases: ['kluski śląskie', 'kluski', 'kluseczki', 'gnocchi'], forms: ['kluskami', 'klusek', 'kopytek', 'kopytkami'], portions: { porcja: 200, sztuka: 20 }, def: 'porcja', addon: [150, 'g'] });
f('placki-ziemniaczane', 'placki ziemniaczane', [230, 25, 4, 13], { aliases: ['placek ziemniaczany', 'placki', 'placuszki'], forms: ['placków', 'placka', 'plackami'], portions: { sztuka: 70 }, def: 'sztuka', sizes: [50, 70, 100] });

// ---------------- Warzywa ----------------
cat('warzywa');
f('pomidor', 'pomidor', [18, 3.9, 0.9, 0.2], { aliases: ['pomidorek'], forms: ['pomidorkiem', 'pomidorka', 'pomidorki', 'pomidorków'], portions: { sztuka: 120, plaster: 15 }, def: 'sztuka', sizes: [80, 120, 200], addon: [2, 'plaster'] });
f('pomidorki-koktajlowe', 'pomidorki koktajlowe', [18, 3.9, 0.9, 0.2], { parent: 'pomidor', aliases: ['pomidorki cherry', 'pomidorek koktajlowy', 'koktajlowe'], portions: { sztuka: 15, garsc: 80 }, def: 'sztuka', addon: [4, 'sztuka'] });
f('ogorek', 'ogórek', [15, 3.6, 0.7, 0.1], { aliases: ['ogórek świeży', 'ogóreczek', 'ogórek zielony'], portions: { sztuka: 150, plaster: 7 }, def: 'sztuka', addon: [3, 'plaster'] });
f('ogorek-kiszony', 'ogórek kiszony', [12, 2.2, 0.7, 0.1], { parent: 'ogorek', aliases: ['ogórek kwaszony', 'kiszony'], portions: { sztuka: 70 }, addon: [1, 'sztuka'] });
f('ogorek-konserwowy', 'ogórek konserwowy', [25, 5, 0.6, 0.2], { parent: 'ogorek', aliases: ['korniszon', 'konserwowy'], portions: { sztuka: 50 }, addon: [1, 'sztuka'] });
f('salata', 'sałata', [15, 2.9, 1.4, 0.2], { aliases: ['sałata lodowa', 'sałata masłowa', 'rukola', 'roszponka', 'mix sałat'], forms: ['sałatą', 'sałaty', 'rukolą', 'rukoli', 'roszponką'], portions: { lisc: 10, garsc: 20, porcja: 50 }, def: 'garsc', addon: [2, 'lisc'] });
f('papryka', 'papryka', [31, 6, 1, 0.3], { aliases: ['papryka czerwona', 'papryczka'], portions: { sztuka: 150, plaster: 15 }, def: 'sztuka', addon: [30, 'g'] });
f('marchew', 'marchew', [41, 9.6, 0.9, 0.2], { aliases: ['marchewka', 'marchewki'], forms: ['marchwi', 'marchwią', 'marchewką', 'marchewkę', 'marchewek'], portions: { sztuka: 80 }, def: 'sztuka' });
f('cebula', 'cebula', [40, 9.3, 1.1, 0.1], { aliases: ['cebulka', 'cebula czerwona'], portions: { sztuka: 100, plaster: 10 }, def: 'sztuka', addon: [20, 'g'] });
f('czosnek', 'czosnek', [149, 33, 6.4, 0.5], { forms: ['czosnkiem', 'czosnku'], portions: { zabek: 5 }, def: 'zabek', addon: [1, 'zabek'] });
f('brokul', 'brokuł', [35, 7, 2.4, 0.4], { source: SRC + '; gotowany', aliases: ['brokuły', 'brokułki'], portions: { porcja: 150, sztuka: 300 }, def: 'porcja', addon: [100, 'g'] });
f('kalafior', 'kalafior', [25, 5, 1.9, 0.3], { source: SRC + '; gotowany', portions: { porcja: 150 }, def: 'porcja', addon: [100, 'g'] });
f('kapusta-kiszona', 'kapusta kiszona', [21, 4.3, 1.1, 0.1], { aliases: ['kiszona kapusta'], portions: { porcja: 100 }, def: 'porcja', addon: [100, 'g'] });
f('kapusta', 'kapusta', [25, 5.8, 1.3, 0.1], { aliases: ['kapusta biała', 'kapusta pekińska', 'kapusta zasmażana', 'kapusta duszona'], portions: { porcja: 100 }, def: 'porcja', addon: [100, 'g'] });
f('surowka', 'surówka', [70, 8, 1, 4], { source: 'przybliżone; surówka warzywna z olejem lub majonezem — bardzo zmienne', aliases: ['surówka z marchewki', 'surówka z kapusty', 'colesław', 'coleslaw', 'surówka colesław'], portions: { porcja: 100 }, def: 'porcja', addon: [100, 'g'] });
f('fasolka-szparagowa', 'fasolka szparagowa', [35, 7.9, 1.9, 0.3], { source: SRC + '; gotowana', aliases: ['fasolka'], portions: { porcja: 150 }, def: 'porcja', addon: [100, 'g'] });
f('groszek', 'groszek zielony', [84, 15.6, 5.4, 0.2], { source: SRC + '; gotowany/konserwowy', aliases: ['groszek', 'groszek konserwowy'], portions: { porcja: 100, lyzka: 15, puszka: 280 }, def: 'porcja', addon: [50, 'g'] });
f('kukurydza', 'kukurydza konserwowa', [80, 15, 2.5, 1.2], { aliases: ['kukurydza', 'kolba kukurydzy'], portions: { lyzka: 15, porcja: 100, puszka: 280, sztuka: 150 }, def: 'lyzka', addon: [2, 'lyzka'] });
f('fasola', 'fasola czerwona', [127, 22.8, 8.7, 0.5], { source: SRC + '; gotowana/konserwowa', aliases: ['fasola', 'fasola biała', 'ciecierzyca', 'soczewica'], forms: ['ciecierzycą', 'ciecierzycy', 'soczewicą', 'soczewicy', 'fasolą'], portions: { porcja: 100, puszka: 240, lyzka: 20 }, def: 'porcja', addon: [80, 'g'] });
f('awokado', 'awokado', [160, 8.5, 2, 14.7], { aliases: ['avocado'], forms: ['awokado'], portions: { sztuka: 150, plaster: 15 }, def: 'sztuka', sizes: [110, 150, 200], addon: [50, 'g'] });
f('pieczarki', 'pieczarki', [22, 3.3, 3.1, 0.3], { aliases: ['pieczarka', 'grzyby', 'grzybki'], forms: ['grzybami', 'grzybów', 'grzybkami'], portions: { sztuka: 20, porcja: 100 }, def: 'porcja', addon: [50, 'g'] });
f('szpinak', 'szpinak', [23, 3.6, 2.9, 0.4], { portions: { garsc: 30, porcja: 100 }, def: 'porcja', addon: [30, 'g'] });
f('rzodkiewka', 'rzodkiewka', [16, 3.4, 0.7, 0.1], { aliases: ['rzodkiewki'], portions: { sztuka: 10 }, def: 'sztuka', addon: [3, 'sztuka'] });
f('burak', 'buraki', [44, 10, 1.7, 0.2], { source: SRC + '; gotowane', aliases: ['burak', 'buraczki', 'ćwikła'], forms: ['buraczkami', 'buraczków', 'ćwikłą'], portions: { porcja: 100, sztuka: 100 }, def: 'porcja', addon: [100, 'g'] });
f('cukinia', 'cukinia', [17, 3.1, 1.2, 0.3], { aliases: ['bakłażan', 'kabaczek'], portions: { sztuka: 250, plaster: 15 }, def: 'sztuka', addon: [50, 'g'] });
f('szczypiorek', 'szczypiorek', [30, 4, 3, 0.5], { aliases: ['koperek', 'natka pietruszki', 'pietruszka', 'koper'], forms: ['koperkiem', 'koperku', 'szczypiorkiem', 'szczypiorku', 'natką'], portions: { lyzka: 5, garsc: 10 }, def: 'lyzka', addon: [1, 'lyzka'] });
f('warzywa', 'warzywa gotowane', [40, 7, 2, 0.5], { aliases: ['warzywa', 'mieszanka warzyw', 'warzywa na patelnię', 'warzywa z wody', 'warzywa na parze', 'bukiet warzyw', 'jarzyny'], forms: ['warzywami', 'warzyw', 'jarzynami', 'jarzyn'], portions: { porcja: 150, garsc: 50 }, def: 'porcja', addon: [100, 'g'] });
f('oliwki', 'oliwki', [145, 4, 1, 15], { aliases: ['oliwka'], portions: { sztuka: 4, garsc: 30, lyzka: 15 }, def: 'sztuka', addon: [5, 'sztuka'] });

// ---------------- Owoce i orzechy ----------------
cat('owoce i orzechy');
f('jablko', 'jabłko', [52, 13.8, 0.3, 0.2], { aliases: ['jabłuszko'], forms: ['jabłuszka', 'jabłuszkiem'], portions: { sztuka: 180, plaster: 15 }, def: 'sztuka', sizes: [130, 180, 240], addon: [1, 'sztuka'] });
f('banan', 'banan', [89, 22.8, 1.1, 0.3], { source: SRC + '; masa bez skórki', portions: { sztuka: 120, plaster: 8 }, def: 'sztuka', sizes: [90, 120, 150], addon: [1, 'sztuka'] });
f('gruszka', 'gruszka', [57, 15, 0.4, 0.1], { portions: { sztuka: 170 }, def: 'sztuka', sizes: [120, 170, 230] });
f('pomarancza', 'pomarańcza', [47, 11.8, 0.9, 0.1], { source: SRC + '; bez skórki', portions: { sztuka: 160 }, def: 'sztuka', sizes: [120, 160, 220] });
f('mandarynka', 'mandarynka', [53, 13, 0.8, 0.3], { aliases: ['klementynka'], portions: { sztuka: 70 }, def: 'sztuka' });
f('truskawki', 'truskawki', [32, 7.7, 0.7, 0.3], { aliases: ['truskawka'], portions: { sztuka: 15, garsc: 80, szklanka: 150, miska: 250 }, def: 'garsc', addon: [80, 'g'] });
f('winogrona', 'winogrona', [69, 18, 0.7, 0.2], { aliases: ['winogrono', 'winogronka'], forms: ['winogron', 'winogronami'], portions: { garsc: 80, kisc: 150 }, def: 'garsc' });
f('borowki', 'borówki', [57, 14.5, 0.7, 0.3], { aliases: ['borówka', 'jagody', 'jagoda', 'borówki amerykańskie'], portions: { garsc: 60, szklanka: 150 }, def: 'garsc', addon: [60, 'g'] });
f('maliny', 'maliny', [52, 12, 1.2, 0.7], { aliases: ['malina'], portions: { garsc: 60, szklanka: 120 }, def: 'garsc', addon: [60, 'g'] });
f('sliwki', 'śliwki', [46, 11.4, 0.7, 0.3], { aliases: ['śliwka'], portions: { sztuka: 35 }, def: 'sztuka' });
f('kiwi', 'kiwi', [61, 14.7, 1.1, 0.5], { portions: { sztuka: 75 }, def: 'sztuka' });
f('arbuz', 'arbuz', [30, 7.6, 0.6, 0.2], { aliases: ['melon'], forms: ['melona', 'melonem'], portions: { kawalek: 300, plaster: 300 }, def: 'kawalek' });
f('brzoskwinia', 'brzoskwinia', [39, 9.5, 0.9, 0.3], { aliases: ['nektarynka', 'morela'], portions: { sztuka: 150 }, def: 'sztuka' });
f('ananas', 'ananas', [50, 13, 0.5, 0.1], { aliases: ['mango'], forms: ['mango'], portions: { plaster: 80, porcja: 150 }, def: 'porcja' });
f('cytryna', 'cytryna', [29, 9, 1.1, 0.3], { aliases: ['limonka'], portions: { plaster: 10, sztuka: 80 }, def: 'plaster', addon: [1, 'plaster'] });
f('rodzynki', 'rodzynki', [299, 79, 3, 0.5], { aliases: ['żurawina suszona', 'bakalie', 'suszone owoce'], portions: { lyzka: 15, garsc: 30 }, def: 'lyzka', addon: [15, 'g'] });
f('daktyle', 'daktyle', [282, 75, 2.5, 0.4], { source: SRC + '; suszone', aliases: ['daktyl', 'figi suszone', 'morele suszone', 'śliwki suszone'], portions: { sztuka: 8 }, def: 'sztuka' });
f('orzechy-wloskie', 'orzechy włoskie', [654, 13.7, 15, 65], { aliases: ['orzechy', 'orzech włoski', 'orzeszki', 'mix orzechów', 'orzechy laskowe', 'orzechy nerkowca', 'nerkowce'], forms: ['orzechami', 'orzechów', 'orzeszkami'], portions: { garsc: 30, sztuka: 5, lyzka: 10 }, def: 'garsc', addon: [15, 'g'] });
f('migdaly', 'migdały', [579, 21.6, 21, 50], { aliases: ['migdał'], portions: { garsc: 30, sztuka: 1.2 }, def: 'garsc', addon: [15, 'g'] });
f('orzeszki-ziemne', 'orzeszki ziemne', [585, 16, 26, 49], { source: SRC + '; prażone', aliases: ['orzeszki solone', 'fistaszki', 'pistacje'], portions: { garsc: 30, opakowanie: 100 }, def: 'garsc' });
f('pestki', 'pestki dyni', [560, 11, 30, 46], { aliases: ['pestki', 'słonecznik', 'pestki słonecznika', 'nasiona chia', 'siemię lniane'], forms: ['słonecznikiem', 'słonecznika', 'chia'], portions: { lyzka: 10, garsc: 25 }, def: 'lyzka', addon: [1, 'lyzka'] });

// ---------------- Tłuszcze, sosy, dodatki ----------------
cat('dodatki');
f('olej', 'olej rzepakowy', [884, 0, 0, 100], { aliases: ['olej', 'olej słonecznikowy', 'tłuszcz'], forms: ['olejem', 'oleju'], portions: { lyzka: 10, lyzeczka: 5 }, def: 'lyzka', addon: [1, 'lyzka'], density: 0.92 });
f('oliwa', 'oliwa z oliwek', [884, 0, 0, 100], { parent: 'olej', aliases: ['oliwa'], forms: ['oliwą', 'oliwy', 'oliwą z oliwek', 'oliwy z oliwek'] });
f('majonez', 'majonez', [680, 1, 1, 75], { aliases: ['majonezik'], portions: { lyzka: 15, lyzeczka: 6 }, def: 'lyzka', addon: [2, 'lyzeczka'] });
f('keczup', 'keczup', [100, 24, 1.5, 0.2], { aliases: ['ketchup', 'sos pomidorowy'], forms: ['ketchupem', 'ketchupu', 'keczupem', 'keczupu', 'sosem pomidorowym'], portions: { lyzka: 15, lyzeczka: 6 }, def: 'lyzka', addon: [1, 'lyzka'] });
f('musztarda', 'musztarda', [120, 10, 5.5, 6], { portions: { lyzeczka: 6, lyzka: 15 }, def: 'lyzeczka', addon: [1, 'lyzeczka'] });
f('sos-czosnkowy', 'sos czosnkowy', [300, 6, 1.5, 30], { aliases: ['sos jogurtowy', 'sos tzatziki', 'tzatziki', 'sos', 'sos do kebaba'], forms: ['sosem', 'sosu'], portions: { lyzka: 15, porcja: 40 }, def: 'lyzka', addon: [2, 'lyzka'] });
f('sos-bolognese', 'sos bolognese', [110, 6, 7, 7], { aliases: ['sos mięsny', 'bolognese'], portions: { porcja: 150, lyzka: 20 }, def: 'porcja', addon: [150, 'g'] });
f('dzem', 'dżem', [250, 62, 0.4, 0.1], { aliases: ['konfitura', 'powidła', 'marmolada', 'dżemik'], forms: ['dżemem', 'dżemu', 'konfiturą', 'powidłami'], portions: { lyzeczka: 10, lyzka: 20 }, def: 'lyzeczka', addon: [2, 'lyzeczka'] });
f('miod', 'miód', [304, 82, 0.3, 0], { aliases: ['miodek', 'syrop klonowy'], portions: { lyzeczka: 12, lyzka: 21 }, def: 'lyzeczka', addon: [1, 'lyzeczka'] });
f('cukier', 'cukier', [400, 100, 0, 0], { aliases: ['cukier biały', 'cukier brązowy'], forms: ['cukrem', 'cukru', 'cukrów'], portions: { lyzeczka: 5, lyzka: 12, kostka: 4 }, def: 'lyzeczka', addon: [1, 'lyzeczka'] });
f('krem-czekoladowy', 'krem czekoladowy', [540, 58, 6, 31], { aliases: ['nutella', 'krem orzechowy'], forms: ['nutellą', 'nutelli'], portions: { lyzeczka: 12, lyzka: 25 }, def: 'lyzeczka', addon: [2, 'lyzeczka'] });
f('maslo-orzechowe', 'masło orzechowe', [588, 20, 25, 50], { aliases: ['masło z orzeszków'], portions: { lyzeczka: 8, lyzka: 16 }, def: 'lyzka', addon: [1, 'lyzka'] });
f('hummus', 'hummus', [170, 14, 8, 10], { forms: ['hummusem', 'hummusu', 'humus', 'humusem'], portions: { lyzka: 20 }, def: 'lyzka', addon: [2, 'lyzka'] });
f('kakao-proszek', 'kakao w proszku', [290, 22, 20, 13], { source: SRC + '; węglowodany przyswajalne (bez błonnika)', aliases: ['kakao naturalne'], portions: { lyzeczka: 5, lyzka: 10 }, def: 'lyzeczka' });

// ---------------- Napoje ----------------
cat('napoje');
f('kawa', 'kawa czarna', [2, 0, 0.3, 0], { aliases: ['kawa', 'kawka', 'kawa czarna bez cukru', 'americano', 'kawa z ekspresu', 'kawa rozpuszczalna', 'kawa parzona'], forms: ['kawkę', 'kawki', 'kawką'], portions: { kubek: 250, filizanka: 150, szklanka: 250 }, def: 'kubek' });
f('espresso', 'espresso', [2, 0, 0.1, 0.2], { parent: 'kawa', aliases: ['kawa espresso', 'doppio'], portions: { filizanka: 30, kubek: 30 }, def: 'filizanka' });
f('herbata', 'herbata', [1, 0.2, 0, 0], { aliases: ['herbatka', 'herbata czarna', 'herbata zielona', 'herbata owocowa', 'napar', 'mięta', 'rumianek'], forms: ['herbatkę', 'herbatki', 'herbatką', 'miętę', 'mięty'], portions: { kubek: 250, szklanka: 250, filizanka: 200 }, def: 'kubek' });
f('woda', 'woda', [0, 0, 0, 0], { aliases: ['woda mineralna', 'woda gazowana', 'woda niegazowana', 'wodę'], portions: { szklanka: 250, butelka: 500 }, def: 'szklanka' });
f('sok-pomaranczowy', 'sok pomarańczowy', [45, 10.4, 0.7, 0.2], { aliases: ['sok', 'sok owocowy', 'soczek', 'sok multiwitamina'], forms: ['sokiem', 'soku', 'soki'], portions: { szklanka: 250, butelka: 330, kubek: 250 }, def: 'szklanka', density: 1.04 });
f('sok-jablkowy', 'sok jabłkowy', [46, 11.3, 0.1, 0.1], { parent: 'sok-pomaranczowy' });
f('cola', 'cola', [42, 10.6, 0, 0], { aliases: ['coca cola', 'pepsi', 'napój gazowany', 'oranżada', 'fanta', 'sprite', 'napój słodzony'], forms: ['colę', 'coli', 'colą'], portions: { puszka: 330, butelka: 500, szklanka: 250 }, def: 'szklanka', density: 1.04 });
f('cola-zero', 'cola zero', [0.3, 0, 0, 0], { parent: 'cola', aliases: ['pepsi max', 'cola light', 'napój zero', 'coca cola zero'] });
f('napoj-energetyczny', 'napój energetyczny', [45, 11, 0, 0], { aliases: ['energetyk', 'red bull', 'monster', 'tiger'], forms: ['energetyka', 'energetyki'], portions: { puszka: 250 }, def: 'puszka', density: 1.04 });
f('piwo', 'piwo', [43, 3.6, 0.5, 0], { aliases: ['piwko', 'piwo jasne', 'lager'], forms: ['piwka', 'piw', 'piwek'], portions: { butelka: 500, puszka: 500, kufel: 500, szklanka: 330 }, def: 'butelka' });
f('piwo-bezalkoholowe', 'piwo bezalkoholowe', [25, 5.5, 0.4, 0], { parent: 'piwo', aliases: ['piwo 0', 'piwo zero', 'bezalkoholowe'] });
f('wino', 'wino czerwone', [85, 2.6, 0.1, 0], { aliases: ['wino', 'wino białe', 'wino wytrawne'], portions: { kieliszek: 150, butelka: 750 }, def: 'kieliszek' });
f('wodka', 'wódka', [230, 0, 0, 0], { aliases: ['wódeczka', 'whisky', 'gin', 'rum', 'nalewka', 'shot'], forms: ['shota', 'shoty', 'shotów'], portions: { kieliszek: 40 }, def: 'kieliszek', density: 0.95 });
f('kakao-napoj', 'kakao', [80, 11, 3.5, 2.5], { source: SRC + '; napój na mleku 2% z cukrem', aliases: ['kakao na mleku', 'czekolada na gorąco', 'gorąca czekolada'], portions: { kubek: 250, szklanka: 250 }, def: 'kubek' });
f('smoothie', 'smoothie', [60, 13, 1, 0.5], { aliases: ['koktajl owocowy', 'koktajl', 'shake'], forms: ['koktajlu', 'koktajlem'], portions: { szklanka: 250, butelka: 330, kubek: 300 }, def: 'szklanka' });
f('kawa-latte', 'latte', [55, 5, 3, 2.5], { source: SRC + '; kawa z mlekiem 2% (ok. 80% mleka)', aliases: ['kawa latte', 'cappuccino', 'flat white', 'kawa mrożona', 'latte macchiato'], portions: { kubek: 300, filizanka: 200 }, def: 'kubek', sizes: [250, 300, 450] });

// ---------------- Słodycze i przekąski ----------------
cat('słodycze i przekąski');
f('czekolada', 'czekolada mleczna', [535, 59, 7.6, 30], { aliases: ['czekolada', 'czekoladka', 'czekolada z orzechami', 'czekolada biała'], forms: ['czekoladką', 'czekoladki', 'czekoladek'], portions: { kostka: 5, rzad: 25, tabliczka: 100 }, def: 'kostka' });
f('czekolada-gorzka', 'czekolada gorzka', [598, 46, 7.8, 43], { parent: 'czekolada', aliases: ['gorzka czekolada', 'czekolada deserowa'] });
f('baton', 'baton czekoladowy', [490, 60, 8, 24], { aliases: ['baton', 'batonik', 'snickers', 'mars', 'twix', 'lion', 'kitkat', 'bounty'], forms: ['batona', 'batony', 'batoników', 'batonika'], portions: { sztuka: 50 }, def: 'sztuka', sizes: [25, 50, 75] });
f('baton-musli', 'baton musli', [400, 65, 6, 13], { parent: 'baton', aliases: ['batonik musli', 'baton zbożowy', 'baton proteinowy'], portions: { sztuka: 40 } });
f('wafelek', 'wafelek', [520, 60, 6, 28], { aliases: ['wafel', 'prince polo', 'grześki', 'góralek'], forms: ['wafelka', 'wafelki', 'wafelków'], portions: { sztuka: 35 }, def: 'sztuka' });
f('ciastko', 'ciastko', [480, 70, 6, 20], { aliases: ['ciasteczko', 'herbatnik', 'herbatniki', 'markizy', 'ciastka owsiane', 'pierniczek', 'krakersy'], forms: ['ciasteczka', 'ciasteczek', 'ciastek', 'ciastkami', 'herbatników', 'krakersów'], portions: { sztuka: 12 }, def: 'sztuka' });
f('ciasto', 'ciasto', [350, 45, 6, 16], { aliases: ['ciasto domowe', 'babka', 'murzynek', 'brownie', 'tort', 'keks'], forms: ['ciasta', 'ciastem', 'tortu', 'babki'], portions: { kawalek: 100 }, def: 'kawalek', sizes: [70, 100, 150] });
f('sernik', 'sernik', [290, 25, 8, 18], { parent: 'ciasto' });
f('szarlotka', 'szarlotka', [260, 38, 3, 11], { parent: 'ciasto', aliases: ['jabłecznik', 'ciasto z jabłkami'] });
f('lody', 'lody', [210, 24, 3.5, 11], { aliases: ['lód', 'lody śmietankowe', 'lody waniliowe', 'lody czekoladowe', 'rożek', 'lody na patyku'], forms: ['lodów', 'lodami', 'loda', 'rożka'], portions: { galka: 50, porcja: 100, sztuka: 70 }, def: 'galka' });
f('chipsy', 'chipsy', [540, 53, 6.5, 34], { aliases: ['czipsy', 'chips', 'chrupki', 'nachosy'], forms: ['chipsów', 'chrupek', 'nachosów'], portions: { garsc: 25, opakowanie: 140, porcja: 30 }, def: 'garsc' });
f('paluszki', 'paluszki słone', [380, 75, 10, 4], { aliases: ['paluszki', 'precelki', 'popcorn'], forms: ['paluszków', 'precelków'], portions: { garsc: 20, opakowanie: 70 }, def: 'garsc' });
f('zelki', 'żelki', [340, 77, 6, 0.2], { aliases: ['żelek', 'cukierki', 'haribo', 'misie żelki'], forms: ['żelek', 'cukierków', 'cukierka'], portions: { garsc: 30, opakowanie: 100, sztuka: 3 }, def: 'garsc' });
f('budyn', 'budyń', [105, 18, 3, 2.5], { source: SRC + '; na mleku 2% z cukrem', aliases: ['kisiel', 'deser mleczny', 'pudding'], forms: ['budyniu', 'budyniem', 'kisielu', 'kisielem'], portions: { kubek: 200, porcja: 200 }, def: 'porcja' });
f('gofr', 'gofr', [290, 35, 7, 14], { source: SRC + '; bez dodatków', aliases: ['gofry', 'gofer'], forms: ['gofra', 'gofrem', 'gofrów'], portions: { sztuka: 80 }, def: 'sztuka' });

// ---------------- Zupy (wartości na 100 g zupy) ----------------
cat('zupy');
const zupa = { talerz: 300, miska: 350, kubek: 250, porcja: 300, chochla: 150 };
f('zupa-pomidorowa', 'zupa pomidorowa', [45, 6, 1, 2], { source: SRC + '; bez makaronu/ryżu, ze śmietaną', aliases: ['pomidorowa', 'pomidorówka'], portions: zupa, def: 'talerz', sizes: [250, 300, 450] });
f('rosol', 'rosół', [25, 1.5, 2, 1.2], { source: SRC + '; bulion z warzywami, bez makaronu', aliases: ['rosołek', 'bulion'], forms: ['rosołu', 'rosołem', 'rosołku'], portions: zupa, def: 'talerz', sizes: [250, 300, 450] });
f('zurek', 'żurek', [50, 5, 2, 2.5], { source: SRC + '; bez jajka i kiełbasy', aliases: ['żur', 'barszcz biały'], forms: ['żurku', 'żurkiem', 'żuru'], portions: zupa, def: 'talerz', sizes: [250, 300, 450] });
f('barszcz', 'barszcz czerwony', [20, 4, 0.8, 0.2], { aliases: ['barszcz', 'barszczyk'], forms: ['barszczu', 'barszczem'], portions: zupa, def: 'kubek', sizes: [200, 250, 350] });
f('zupa-ogorkowa', 'zupa ogórkowa', [45, 5, 1, 2.3], { aliases: ['ogórkowa', 'ogórkówka'], portions: zupa, def: 'talerz', sizes: [250, 300, 450] });
f('grochowka', 'grochówka', [95, 11, 5.5, 3.5], { aliases: ['zupa grochowa', 'fasolowa', 'zupa fasolowa'], portions: zupa, def: 'talerz', sizes: [250, 300, 450] });
f('krupnik', 'krupnik', [55, 7, 2, 2], { aliases: ['zupa krupnik'], portions: zupa, def: 'talerz', sizes: [250, 300, 450] });
f('kapusniak', 'kapuśniak', [40, 4, 1.5, 2], { aliases: ['zupa z kapusty'], portions: zupa, def: 'talerz', sizes: [250, 300, 450] });
f('zupa-jarzynowa', 'zupa jarzynowa', [40, 6, 1.3, 1.3], { aliases: ['jarzynowa', 'zupa warzywna', 'zupa krem', 'krem z dyni', 'krem z brokułów', 'zupa', 'zupka'], forms: ['zupę', 'zupy', 'zupką'], portions: zupa, def: 'talerz', sizes: [250, 300, 450] });
f('flaki', 'flaki', [80, 3, 9, 3.5], { aliases: ['flaczki'], forms: ['flaków', 'flaczków'], portions: zupa, def: 'talerz', sizes: [250, 300, 450] });

// ---------------- Dania gotowe (liczone jako całość) ----------------
cat('dania gotowe');
f('pierogi', 'pierogi', [190, 30, 6, 5.5], { source: SRC + '; typu ruskie, gotowane', aliases: ['pieróg', 'pierożki', 'pierogi ruskie', 'ruskie'], forms: ['pieroga', 'pierogów', 'pierogami', 'pierożków', 'pierożkami', 'ruskich'], portions: { sztuka: 45, porcja: 270 }, def: 'sztuka', sizes: [30, 45, 60] });
f('pierogi-z-miesem', 'pierogi z mięsem', [210, 25, 10, 8], { parent: 'pierogi', forms: ['pierogów z mięsem', 'pierogami z mięsem', 'pieroga z mięsem'] });
f('pierogi-z-kapusta', 'pierogi z kapustą i grzybami', [170, 28, 4.5, 4.5], { parent: 'pierogi', aliases: ['pierogi z kapustą', 'pierogi z grzybami'], forms: ['pierogów z kapustą', 'pierogów z kapustą i grzybami'] });
f('pierogi-z-serem', 'pierogi z serem', [200, 30, 8, 5], { parent: 'pierogi', aliases: ['pierogi na słodko', 'pierogi z owocami', 'pierogi z truskawkami', 'pierogi z jagodami'], forms: ['pierogów z serem'] });
f('uszka', 'uszka', [220, 30, 6, 8], { aliases: ['uszko'], forms: ['uszkami', 'uszek'], portions: { sztuka: 8, porcja: 80 }, def: 'porcja', addon: [80, 'g'] });
f('bigos', 'bigos', [120, 6, 7, 8], { portions: { porcja: 250, talerz: 300, miska: 300 }, def: 'porcja', sizes: [180, 250, 350] });
f('golabki', 'gołąbki', [125, 9, 7, 7], { aliases: ['gołąbek'], forms: ['gołąbków', 'gołąbka', 'gołąbkami'], portions: { sztuka: 180 }, def: 'sztuka', sizes: [130, 180, 250] });
f('gulasz', 'gulasz', [140, 4, 14, 8], { aliases: ['gulasz wieprzowy', 'gulasz wołowy', 'strogonow', 'potrawka'], portions: { porcja: 250, talerz: 300 }, def: 'porcja', sizes: [180, 250, 350] });
f('leczo', 'leczo', [60, 6, 3, 3], { portions: { talerz: 300, porcja: 300, miska: 350 }, def: 'talerz' });
f('pizza', 'pizza', [250, 32, 11, 9], { source: SRC + '; typu margherita/capricciosa', aliases: ['pizza margherita', 'pizza capricciosa', 'pizza pepperoni', 'pica'], forms: ['pizzę', 'pizzy', 'pizzą', 'picę', 'picy'], portions: { kawalek: 110, sztuka: 450, porcja: 450 }, def: 'sztuka', sizes: [300, 450, 650] });
f('kebab', 'kebab', [215, 20, 11, 10], { source: SRC + '; w bułce/picie z sosem i surówką', aliases: ['kebab w bułce', 'kebab w picie', 'kebab w tortilli', 'rollo kebab', 'döner', 'shoarma'], forms: ['kebaba', 'kebaby', 'kebabem'], portions: { sztuka: 400, porcja: 400 }, def: 'sztuka', sizes: [300, 400, 550] });
f('hamburger', 'hamburger', [250, 25, 13, 11], { aliases: ['burger', 'cheeseburger', 'big mac', 'kanapka z mcdonalda'], forms: ['burgera', 'burgerem', 'burgery', 'hamburgera'], portions: { sztuka: 220 }, def: 'sztuka', sizes: [120, 220, 330] });
f('zapiekanka', 'zapiekanka', [230, 28, 9, 9], { aliases: ['zapiekanka z pieczarkami', 'zapiekanka makaronowa', 'lasagne', 'lazania', 'tortilla zapiekana'], portions: { sztuka: 250, porcja: 300 }, def: 'sztuka', sizes: [180, 250, 400] });
f('salatka-grecka', 'sałatka grecka', [100, 4, 3, 8], { aliases: ['sałatka z fetą', 'sałatka cezar', 'sałatka caesar'], portions: { porcja: 250, miska: 300 }, def: 'porcja', sizes: [180, 250, 350] });
f('salatka-jarzynowa', 'sałatka jarzynowa', [150, 9, 3, 11], { aliases: ['sałatka warzywna z majonezem', 'sałatka ziemniaczana', 'sałatka śledziowa', 'śledź pod pierzynką'], portions: { porcja: 150, lyzka: 30 }, def: 'porcja' });
f('sushi', 'sushi', [150, 28, 5, 2], { aliases: ['maki', 'nigiri', 'california roll'], portions: { sztuka: 30, porcja: 240 }, def: 'sztuka' });
f('jajecznica-gotowa', 'pasta jajeczna', [200, 1.5, 10, 17], { aliases: ['pasta z jajek', 'jajka z majonezem w paście'], portions: { lyzka: 25, porcja: 80 }, def: 'lyzka', addon: [2, 'lyzka'] });
f('kanapka-sklepowa', 'kanapka gotowa', [250, 30, 11, 9], { aliases: ['kanapka ze sklepu', 'sandwich', 'kanapka z żabki', 'panini', 'bajgiel'], portions: { sztuka: 180 }, def: 'sztuka' });

export const FOODS = out;
