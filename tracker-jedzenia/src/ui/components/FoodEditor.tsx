// Edycja/dodawanie produktu i dania. Zmiany zapisywane jako UserOverride (przywracalne).

import { useState } from 'react';
import { computeItem } from '../../core/calculator.ts';
import { overrideKey, resolveFood } from '../../core/db.ts';
import { DEFAULT_DATA } from '../../core/defaults.ts';
import { makeUserFood, refreshForms, slugify } from '../../core/personal.ts';
import type { Dish, DishIngredient, Food, Macros } from '../../core/types.ts';
import { useApp } from '../state.tsx';
import { FoodPicker, Modal, NumberInput } from './common.tsx';

const splitList = (s: string) => s.split(',').map((x) => x.trim()).filter(Boolean);
const defaultFood = (id: string) => DEFAULT_DATA.foods.find((f) => f.id === id);
const defaultDish = (id: string) => DEFAULT_DATA.dishes.find((d) => d.id === id);

function UnitKeySelect({ value, onChange }: { value: string; onChange: (u: string) => void }) {
  const { db } = useApp();
  return (
    <select aria-label="Jednostka porcji" value={value} onChange={(e) => onChange(e.target.value)} style={{ width: 'auto' }}>
      {Object.entries(db.modifiers.units)
        .filter(([, u]) => u.grams === undefined)
        .map(([k, u]) => (
          <option key={k} value={k}>
            {u.label}
          </option>
        ))}
      <option value="g">g</option>
    </select>
  );
}

export function FoodEditor({ foodId, initialName = '', onClose }: { foodId?: string; initialName?: string; onClose: () => void }) {
  const app = useApp();
  const { db } = app;
  const existing = foodId ? db.foods.get(foodId) : undefined;
  const resolved = foodId ? resolveFood(db, foodId) : null;
  const origin = foodId ? (db.origin.get(`food:${foodId}`) ?? 'default') : 'user';
  const [name, setName] = useState(existing?.name ?? initialName);
  const [aliases, setAliases] = useState((existing?.aliases ?? []).join(', '));
  const [per100, setPer100] = useState<Macros>(resolved?.per100 ?? { kcal: 0, carbs: 0, protein: 0, fat: 0 });
  const [portions, setPortions] = useState<[string, number][]>(Object.entries(existing?.portions ?? (existing ? {} : { porcja: 100 })));
  const [def, setDef] = useState(existing?.defaultPortion ?? '');
  const [sizes, setSizes] = useState(existing?.sizes ?? {});
  const [addon, setAddon] = useState(existing?.addon ?? null);
  const [msg, setMsg] = useState<string | null>(null);
  const inherits = !!existing?.parentId;

  const save = async () => {
    const portionsObj = Object.fromEntries(portions.filter(([k, v]) => k && v > 0));
    if (!name.trim()) return setMsg('Podaj nazwę.');
    if (!existing) {
      const o = makeUserFood({ name, aliases: splitList(aliases), per100, portions: portionsObj, defaultPortion: def }, new Set(db.foods.keys()));
      await app.saveOverride(o);
      onClose();
      return;
    }
    const keep = defaultFood(existing.id)?.forms ?? [];
    let data: Food = {
      ...existing,
      name: name.trim().toLowerCase(),
      aliases: splitList(aliases),
      portions: portionsObj,
      sizes,
      ...(addon ? { addon } : {}),
    };
    if (!addon) delete data.addon;
    if (!inherits || JSON.stringify(per100) !== JSON.stringify(resolved?.per100)) data.per100 = per100;
    if (def && portionsObj[def]) data.defaultPortion = def;
    data = refreshForms(data, keep);
    await app.saveOverride({ key: overrideKey('food', existing.id), kind: 'food', id: existing.id, data, isNew: origin === 'user', updatedAt: Date.now() });
    onClose();
  };

  const macroField = (k: keyof Macros, label: string) => (
    <label className="field">
      {label}
      <NumberInput label={label} value={per100[k]} width="100%" onChange={(n) => setPer100({ ...per100, [k]: n })} />
    </label>
  );

  return (
    <Modal title={existing ? `Produkt: ${existing.name}` : 'Nowy produkt'} onClose={onClose}>
      <div className="stack">
        {origin !== 'default' && <span className="badge ok">{origin === 'user' ? 'Twój produkt' : 'Zmieniony przez Ciebie'}</span>}
        <label className="field">
          Nazwa
          <input type="text" value={name} onChange={(e) => setName(e.target.value)} />
        </label>
        <label className="field">
          Inne nazwy (po przecinku) — formy odmiany tworzą się same
          <input type="text" value={aliases} onChange={(e) => setAliases(e.target.value)} placeholder="np. kajzerka, bułeczka" />
        </label>
        <div>
          <div className="small muted" style={{ marginBottom: 4 }}>
            Wartości na 100 g{inherits ? ` (odziedziczone po: ${db.foods.get(existing!.parentId!)?.name ?? existing!.parentId}, chyba że zmienisz)` : ''}
          </div>
          <div className="grid4">
            {macroField('kcal', 'kcal')}
            {macroField('protein', 'białko g')}
            {macroField('carbs', 'węglowodany g')}
            {macroField('fat', 'tłuszcz g')}
          </div>
        </div>
        <div className="stack">
          <div className="small muted">Porcje nazwane (gramy){inherits ? ' — puste = jak u produktu bazowego' : ''}</div>
          {portions.map(([k, v], i) => (
            <div className="row" key={i}>
              <UnitKeySelect value={k} onChange={(u) => setPortions(portions.map((p, j) => (j === i ? [u, p[1]] : p)))} />
              <NumberInput label={`gramy porcji ${k}`} value={v} onChange={(n) => setPortions(portions.map((p, j) => (j === i ? [p[0], n] : p)))} />
              <label className="row small">
                <input type="radio" name="defportion" checked={def === k} onChange={() => setDef(k)} /> domyślna
              </label>
              <button className="btn small ghost" aria-label="Usuń porcję" onClick={() => setPortions(portions.filter((_, j) => j !== i))}>
                ✕
              </button>
            </div>
          ))}
          <button className="btn small" style={{ justifySelf: 'start' }} onClick={() => setPortions([...portions, ['sztuka', 100]])}>
            + porcja
          </button>
        </div>
        <div>
          <div className="small muted" style={{ marginBottom: 4 }}>
            Gramy porcji domyślnej dla rozmiarów (puste = mnożnik globalny)
          </div>
          <div className="grid4" style={{ gridTemplateColumns: 'repeat(3, 1fr)' }}>
            {(['small', 'standard', 'large'] as const).map((s) => (
              <label className="field" key={s}>
                {s === 'small' ? 'mała' : s === 'large' ? 'duża' : 'standard'}
                <input
                  type="text"
                  inputMode="decimal"
                  value={sizes[s] ?? ''}
                  onChange={(e) => {
                    const n = Number(e.target.value.replace(',', '.'));
                    const next = { ...sizes };
                    if (e.target.value === '' || !Number.isFinite(n)) delete next[s];
                    else next[s] = n;
                    setSizes(next);
                  }}
                />
              </label>
            ))}
          </div>
        </div>
        <div className="row small">
          <span className="muted">Jako dodatek („z …”):</span>
          {addon ? (
            <>
              <NumberInput label="ilość dodatku" value={addon.qty} onChange={(n) => setAddon({ ...addon, qty: n })} />
              <UnitKeySelect value={addon.unit} onChange={(u) => setAddon({ ...addon, unit: u })} />
              <button className="btn small ghost" onClick={() => setAddon(null)}>
                ✕
              </button>
            </>
          ) : (
            <button className="btn small" onClick={() => setAddon({ qty: 1, unit: def || 'porcja' })}>
              ustaw
            </button>
          )}
        </div>
        {existing?.source && <div className="small muted">Źródło: {existing.source}{existing.verified === false ? ' (niezweryfikowane)' : ''}</div>}
        {msg && <div className="notice">{msg}</div>}
        <div className="row">
          <button className="btn primary" onClick={save}>
            Zapisz
          </button>
          {origin === 'changed' && (
            <button
              className="btn"
              onClick={async () => {
                await app.removeOverride(overrideKey('food', foodId!));
                onClose();
              }}
            >
              Przywróć domyślne
            </button>
          )}
          {origin === 'user' && foodId && (
            <button
              className="btn danger"
              onClick={async () => {
                await app.removeOverride(overrideKey('food', foodId));
                onClose();
              }}
            >
              Usuń produkt
            </button>
          )}
        </div>
      </div>
    </Modal>
  );
}

export function DishEditor({ dishId, onClose }: { dishId?: string; onClose: () => void }) {
  const app = useApp();
  const { db, calc } = app;
  const existing = dishId ? db.dishes.get(dishId) : undefined;
  const origin = dishId ? (db.origin.get(`dish:${dishId}`) ?? 'default') : 'user';
  const [name, setName] = useState(existing?.name ?? '');
  const [aliases, setAliases] = useState((existing?.aliases ?? []).join(', '));
  const [ings, setIngs] = useState<DishIngredient[]>(existing?.ingredients ?? []);
  const [sizeMode, setSizeMode] = useState<'main' | 'all'>(existing?.sizeMode ?? 'main');
  const preview = computeItem(db, { kind: 'dish', matchedId: '__preview', ingredients: ings, quantity: 1, unit: null, size: null, modifiers: [], factor: 1, confidence: 1, fragment: '', changes: [] }, calc);

  const save = async () => {
    if (!name.trim() || !ings.length) return;
    const id = existing?.id ?? `user-${slugify(name)}`;
    const data: Dish = refreshForms(
      { ...(existing ?? { id, signature: false, category: 'moje', source: 'definicja użytkownika' }), id, name: name.trim().toLowerCase(), aliases: splitList(aliases), ingredients: ings, sizeMode },
      defaultDish(id)?.forms ?? [],
    );
    await app.saveOverride({ key: overrideKey('dish', id), kind: 'dish', id, data, isNew: origin === 'user', updatedAt: Date.now() });
    onClose();
  };

  return (
    <Modal title={existing ? `Danie: ${existing.name}` : 'Nowe danie'} onClose={onClose}>
      <div className="stack">
        {origin !== 'default' && <span className="badge ok">{origin === 'user' ? 'Twoje danie' : 'Zmienione przez Ciebie'}</span>}
        <label className="field">
          Nazwa
          <input type="text" value={name} onChange={(e) => setName(e.target.value)} />
        </label>
        <label className="field">
          Inne nazwy (po przecinku)
          <input type="text" value={aliases} onChange={(e) => setAliases(e.target.value)} />
        </label>
        <div className="small muted">Skład (pierwszy składnik = główny; zaznacz „domyślny”, jeśli można go wyłączyć słowem „bez”):</div>
        {ings.map((ing, i) => (
          <div className="row" key={i}>
            <span style={{ flex: 1 }}>{db.foods.get(ing.foodId)?.name ?? ing.foodId}</span>
            <NumberInput label="ilość" value={ing.qty} onChange={(n) => setIngs(ings.map((x, j) => (j === i ? { ...x, qty: n } : x)))} />
            <UnitKeySelect value={ing.unit} onChange={(u) => setIngs(ings.map((x, j) => (j === i ? { ...x, unit: u } : x)))} />
            <label className="row small">
              <input type="checkbox" checked={!!ing.optional} onChange={(e) => setIngs(ings.map((x, j) => (j === i ? { ...x, optional: e.target.checked || undefined } : x)))} /> domyślny
            </label>
            <button className="btn small ghost" aria-label="Usuń składnik" onClick={() => setIngs(ings.filter((_, j) => j !== i))}>
              ✕
            </button>
          </div>
        ))}
        <FoodPicker
          kinds={['food']}
          placeholder="Dodaj składnik…"
          onPick={(s) => {
            const rf = resolveFood(db, s.id);
            setIngs([...ings, { foodId: s.id, qty: 1, unit: rf?.defaultPortion ?? 'porcja' }]);
          }}
        />
        <label className="field">
          Rozmiar („duża …”) zmienia
          <select value={sizeMode} onChange={(e) => setSizeMode(e.target.value as 'main' | 'all')}>
            <option value="main">tylko składnik główny</option>
            <option value="all">całe danie</option>
          </select>
        </label>
        <div className="small">
          Porcja: <b>{Math.round(preview.totals.kcal)} kcal</b>, {Math.round(preview.grams)} g
        </div>
        <div className="row">
          <button className="btn primary" onClick={save} disabled={!name.trim() || !ings.length}>
            Zapisz
          </button>
          {origin === 'changed' && (
            <button
              className="btn"
              onClick={async () => {
                await app.removeOverride(overrideKey('dish', dishId!));
                onClose();
              }}
            >
              Przywróć domyślne
            </button>
          )}
          {origin === 'user' && dishId && (
            <button
              className="btn danger"
              onClick={async () => {
                await app.removeOverride(overrideKey('dish', dishId));
                onClose();
              }}
            >
              Usuń danie
            </button>
          )}
        </div>
      </div>
    </Modal>
  );
}

export { FoodPicker };
