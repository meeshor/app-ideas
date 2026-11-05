// Model danych aplikacji „Zjadłem”. Czysty TypeScript, bez zależności od UI.

/** Makroskładniki: kcal oraz gramy węglowodanów, białka i tłuszczu. */
export interface Macros {
  kcal: number;
  carbs: number;
  protein: number;
  fat: number;
}

/** Klasy rozmiaru. `huge` nie ma gramów w produktach — zawsze mnożnik globalny. */
export type SizeKey = 'small' | 'standard' | 'large' | 'huge';
export const SIZE_KEYS: readonly SizeKey[] = ['small', 'standard', 'large', 'huge'];

/** Klucz jednostki/porcji, np. 'g', 'ml', 'sztuka', 'plaster', 'lyzka'. */
export type UnitKey = string;

/**
 * Produkt. Wariant to ten sam typ z `parentId`: nadpisuje tylko podane pola,
 * resztę dziedziczy po rodzicu (np. „bułka żytnia” zmienia makro, masę sztuki bierze z „bułki”).
 */
export interface Food {
  id: string;
  name: string;
  parentId?: string;
  /** Wartości na 100 g produktu (jadalnej części). */
  per100?: Macros;
  /** Porcje nazwane: jednostka → gramy, np. { sztuka: 60, plaster: 15 }. */
  portions?: Record<UnitKey, number>;
  /** Porcja domyślna (gdy użytkownik nie poda jednostki). */
  defaultPortion?: UnitKey;
  /** Gramy porcji domyślnej dla klas rozmiaru (pierwszeństwo przed mnożnikiem globalnym). */
  sizes?: Partial<Record<Exclude<SizeKey, 'huge'>, number>>;
  /** Ile dodać, gdy produkt jest dodatkiem „z X” (np. ser do kanapki: 1 plaster). */
  addon?: { qty: number; unit: UnitKey };
  /** Gęstość g/ml do przeliczania jednostek objętości (domyślnie 1). */
  density?: number;
  /** Nazwy bazowe i synonimy (pisane ręcznie). */
  aliases?: string[];
  /** Formy odmiany (generowane regułami końcówek, poprawiane ręcznie). */
  forms?: string[];
  category?: string;
  /** Pochodzenie wartości, np. „przybliżone, typowe wartości z tabel NIZP-PZH/USDA”. */
  source?: string;
  /** false = wartość przybliżona, niezweryfikowana ze źródłem. */
  verified?: boolean;
}

export interface DishIngredient {
  foodId: string;
  qty: number;
  unit: UnitKey;
  /** Składnik domyślny, który można wyłączyć („bez masła”). */
  optional?: boolean;
}

/** Danie złożone („przepis”). */
export interface Dish {
  id: string;
  name: string;
  aliases?: string[];
  forms?: string[];
  ingredients: DishIngredient[];
  /** Indeks składnika głównego (domyślnie 0) — do niego stosuje się rozmiar i podmiana wariantu. */
  main?: number;
  /** 'main': rozmiar zmienia tylko składnik główny; 'all': skaluje całe danie (zupy, dania na talerzu). */
  sizeMode?: 'main' | 'all';
  category?: string;
  source?: string;
  verified?: boolean;
  /** Czy danie można rozpoznać przez sygnaturę („<główny> z <dodatki>”). Domyślnie true. */
  signature?: boolean;
}

export interface UnitDef {
  label: string;
  /** Formy w tekście (odmiana, skróty). */
  forms: string[];
  /** Jednostka masy: ile gramów. */
  grams?: number;
  /** Jednostka objętości: ile ml. */
  ml?: number;
  /** Wartość zapasowa w gramach, gdy produkt nie ma tej porcji (obniżona pewność). */
  fallbackGrams?: number;
  /** Etykieta w liczbie mnogiej / dopełniaczu do rozbicia („2 plastry”). */
  plural?: string;
  /** Forma dla 5+ („5 plastrów”). */
  genitivePlural?: string;
}

export interface SizeDef {
  label: string;
  forms: string[];
  /** Mnożnik globalny (zapasowy). Ustawienia użytkownika mogą go nadpisać. */
  multiplier: number;
}

export interface AmountDef {
  id: string;
  label: string;
  /** Frazy (mogą być wielowyrazowe), np. „dużo”, „dużą ilością”. */
  forms: string[];
  multiplier: number;
}

/** Modyfikatory i słownik pomocniczy parsera. */
export interface ModifiersData {
  sizes: Record<SizeKey, SizeDef>;
  amounts: AmountDef[];
  /** Słowa negacji składnika („bez”). */
  negations: string[];
  /** Słowa dołączające dodatki („z”, „ze”, „na”). */
  attachMarkers: string[];
  /** Separatory pozycji („i”, „oraz”, „plus”…). Interpunkcja (, + ;) jest zawsze separatorem. */
  separators: string[];
  /** Słowa do pominięcia („zjadłem”, „potem”…). */
  fillers: string[];
  /** Liczebniki słowne. */
  numberWords: Record<string, number>;
  units: Record<UnitKey, UnitDef>;
  /** Słowa nazw posiłków → posiłek (podpowiedź z tekstu, np. „na śniadanie”). */
  mealWords: Record<string, Meal>;
}

export type Meal = 'breakfast' | 'lunch' | 'dinner' | 'snack';
export const MEALS: readonly Meal[] = ['breakfast', 'lunch', 'dinner', 'snack'];

// ---------- Parser ----------

export type IngredientChange =
  | { op: 'add'; foodId: string; qty: number; unit: UnitKey | null; size?: SizeKey | null; factor?: number; fragment: string }
  | { op: 'remove'; foodId: string; fragment: string }
  | { op: 'set'; foodId: string; qty: number; unit: UnitKey | null; fragment: string }
  | { op: 'scale'; foodId: string; factor: number; fragment: string }
  | { op: 'variant'; foodId: string; fragment: string };

/** Pozycja rozpoznana przez parser. */
export interface ParsedItem {
  kind: 'food' | 'dish';
  matchedId: string;
  /** Ilość (sztuki porcji / porcje dania / gramy przy unit='g'). */
  quantity: number;
  /** Jednostka; null = porcja domyślna. */
  unit: UnitKey | null;
  size: SizeKey | null;
  /** Słowny opis zastosowanych modyfikatorów (do wyświetlenia). */
  modifiers: string[];
  /** Mnożnik ilości („dużo X”). */
  factor: number;
  /** 0–1: 1 = dokładne dopasowanie, mniej = bez polskich znaków / literówka / jednostka zapasowa. */
  confidence: number;
  /** Fragment tekstu, z którego powstała pozycja (znormalizowany). */
  fragment: string;
  /** Zmiany składników względem dania / dodatki do produktu. */
  changes: IngredientChange[];
  /** Jawna lista składników po ręcznej edycji (zastępuje skład dania). */
  ingredients?: DishIngredient[];
}

export interface ParseResult {
  items: ParsedItem[];
  /** Niezrozumiane fragmenty tekstu. */
  unknown: string[];
  mealHint?: Meal;
}

/** Wspólny interfejs parsera: reguły teraz, opcjonalnie LLM (tekst → struktura) później. */
export interface Parser {
  readonly id: string;
  parse(text: string): ParseResult | Promise<ParseResult>;
}

// ---------- Kalkulator ----------

export interface BreakdownLine {
  foodId: string;
  foodName: string;
  grams: number;
  macros: Macros;
  /** Czytelny opis, np. „bułka pszenna 60 g × 1,2 (duża) = 72 g → 198 kcal”. */
  explain: string;
  /** Czy użyto wartości zapasowej (porcja ogólna / mnożnik globalny). */
  approximate: boolean;
}

export interface ComputedItem {
  label: string;
  lines: BreakdownLine[];
  /** Składniki usunięte („bez masła”) — do wyświetlenia. */
  removed: string[];
  totals: Macros;
  grams: number;
  confidence: number;
}

// ---------- Dziennik i ustawienia ----------

export interface LogEntry {
  id: string;
  /** YYYY-MM-DD (czas lokalny). */
  date: string;
  /** HH:MM */
  time: string;
  meal: Meal;
  /** Oryginalny tekst wpisu. */
  text: string;
  /** Wynik parsowania (po ewentualnych poprawkach użytkownika). */
  items: ParsedItem[];
  /** Wyliczenie z chwili zapisu — zmiana bazy nie przepisuje historii. */
  computed: ComputedItem[];
  totals: Macros;
  createdAt: number;
  updatedAt?: number;
}

export type OverrideKind = 'food' | 'dish' | 'modifiers';

/** Osobiste definicje i poprawki — pierwszeństwo przed danymi domyślnymi. */
export interface UserOverride {
  key: string; // `${kind}:${id}`
  kind: OverrideKind;
  id: string;
  /** Pełny rekord po zmianie (Food / Dish / ModifiersData) albo null = ukryty (usunięty). */
  data: Food | Dish | ModifiersData | null;
  /** true = rekord dodany przez użytkownika (nie ma odpowiednika w danych domyślnych). */
  isNew: boolean;
  updatedAt: number;
}

export type Sex = 'female' | 'male';
export type Activity = 'sedentary' | 'light' | 'moderate' | 'active' | 'very_active';
export type GoalKind = 'lose' | 'maintain' | 'gain';

export interface Profile {
  sex: Sex;
  age: number;
  heightCm: number;
  weightKg: number;
  activity: Activity;
  goal: GoalKind;
}

export interface MacroSplit {
  /** Procent energii z węglowodanów, białka, tłuszczu (suma 100). */
  carbs: number;
  protein: number;
  fat: number;
}

export interface Settings {
  profile: Profile | null;
  split: MacroSplit;
  /** Ręczne cele (nadpisują wyliczone, jeśli podane). */
  manualGoals: Partial<Macros> | null;
  /** Mnożniki rozmiarów (nadpisują modifiers.json). */
  sizeMultipliers: Partial<Record<SizeKey, number>>;
  theme: 'auto' | 'light' | 'dark';
}
