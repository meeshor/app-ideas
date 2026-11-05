// Edycja jednej pozycji w podglądzie: produkt, ilość, jednostka, rozmiar, skład; „Zapamiętaj jako moje”.

import { useState } from 'react';
import { computeItem, itemLabel } from '../../core/calculator.ts';
import { resolveFood } from '../../core/db.ts';
import { fmtNum } from '../../core/format.ts';
import { makePersonalDefinition, materialize } from '../../core/personal.ts';
import type { DishIngredient, ParsedItem, SizeKey } from '../../core/types.ts';
import { useApp } from '../state.tsx';
import { FoodPicker, NumberInput } from './common.tsx';

const SIZE_OPTIONS: { v: SizeKey | ''; l: string }[] = [
  { v: '', l: 'bez rozmiaru' },
  { v: 'small', l: 'mała' },
  { v: 'standard', l: 'standard' },
  { v: 'large', l: 'duża' },
  { v: 'huge', l: 'ogromna' },
];

function UnitSelect({ foodId, value, onChange, allowDefault }: { foodId: string; value: string | null; onChange: (u: string | null) => void; allowDefault: boolean }) {
  const { db } = useApp();
  const rf = resolveFood(db, foodId);
  const units = db.modifiers.units;
  const keys = Object.keys(rf?.portions ?? {});
  const opts = [...keys, 'g', 'ml'];
  if (value && !opts.includes(value)) opts.push(value);
  return (
    <select aria-label="Jednostka" value={value ?? ''} onChange={(e) => onChange(e.target.value || null)}>
      {allowDefault && <option value="">{rf?.defaultPortion ? `${units[rf.defaultPortion]?.label ?? rf.defaultPortion} (domyślna)` : 'porcja'}</option>}
      {opts.map((u) => (
        <option key={u} value={u}>
          {units[u]?.label ?? u}
          {rf?.portions[u] ? ` (${fmtNum(rf.portions[u]!)} g)` : ''}
        </option>
      ))}
    </select>
  );
}

export function ItemEditor({ item, onChange, onRemove }: { item: ParsedItem; onChange: (it: ParsedItem) => void; onRemove: () => void }) {
  const app = useApp();
  const { db, calc } = app;
  const [saved, setSaved] = useState<string | null>(null);
  const isComposite = item.kind === 'dish' || item.changes.some((c) => c.op === 'add');
  const update = (patch: Partial<ParsedItem>) => {
    setSaved(null);
    onChange({ ...item, ...patch, edited: true });
  };

  const ingredients: DishIngredient[] = item.ingredients ?? materialize(db, item, calc);
  /** Przejście na jawny skład (po pierwszej zmianie składnika). */
  const setIngredients = (list: DishIngredient[]) => {
    const label = itemLabel(db, item);
    const matchedId = item.kind === 'dish' ? item.matchedId : `custom:${item.matchedId}`;
    update({ kind: 'dish', matchedId, ingredients: list, label, quantity: 1, unit: null, size: null, factor: 1 });
  };
  const def = item.edited || item.changes.length ? makePersonalDefinition(db, item, calc) : null;

  return (
    <div className="editor" data-testid="item-editor">
      {!item.ingredients && (
        <>
          <div className="row">
            <label className="field" style={{ flex: '0 0 auto' }}>
              Ilość
              <NumberInput label="Ilość" value={item.quantity} step={0.5} onChange={(n) => update({ quantity: n })} />
            </label>
            {item.kind === 'food' ? (
              <label className="field" style={{ flex: 1 }}>
                Jednostka
                <UnitSelect foodId={item.matchedId} value={item.unit} allowDefault onChange={(u) => update({ unit: u })} />
              </label>
            ) : (
              <span className="muted small" style={{ alignSelf: 'end', paddingBottom: 10 }}>
                porcje dania
              </span>
            )}
            <label className="field" style={{ flex: 1 }}>
              Rozmiar
              <select aria-label="Rozmiar" value={item.size ?? ''} onChange={(e) => update({ size: (e.target.value || null) as SizeKey | null })}>
                {SIZE_OPTIONS.map((o) => (
                  <option key={o.v} value={o.v}>
                    {o.l}
                  </option>
                ))}
              </select>
            </label>
          </div>
          <label className="field">
            Inny produkt lub danie
            <FoodPicker
              placeholder={`Zamiast: ${itemLabel(db, item)}`}
              onPick={(s) => update({ kind: s.kind, matchedId: s.id, unit: s.kind === 'food' && item.unit && resolveFood(db, s.id)?.portions[item.unit] ? item.unit : null, changes: item.changes.filter((c) => c.op !== 'variant' && c.op !== 'set'), confidence: 1 })}
            />
          </label>
        </>
      )}

      {(isComposite || item.ingredients) && (
        <div className="stack">
          <div className="small muted">Skład{item.ingredients ? ' (edytowany)' : ''}:</div>
          {ingredients.map((ing, i) => (
            <div className="ing" key={`${ing.foodId}-${i}`}>
              <span>{db.foods.get(ing.foodId)?.name ?? ing.foodId}</span>
              <NumberInput label={`Ilość: ${db.foods.get(ing.foodId)?.name ?? ''}`} value={ing.qty} onChange={(n) => setIngredients(ingredients.map((x, j) => (j === i ? { ...x, qty: n } : x)))} />
              <UnitSelect foodId={ing.foodId} value={ing.unit} allowDefault={false} onChange={(u) => setIngredients(ingredients.map((x, j) => (j === i ? { ...x, unit: u ?? 'g' } : x)))} />
              <button className="btn small ghost" aria-label={`Usuń składnik ${db.foods.get(ing.foodId)?.name ?? ''}`} onClick={() => setIngredients(ingredients.filter((_, j) => j !== i))}>
                ✕
              </button>
            </div>
          ))}
          <FoodPicker
            kinds={['food']}
            placeholder="Dodaj składnik…"
            onPick={(s) => {
              const rf = resolveFood(db, s.id);
              const add = rf?.addon ?? { qty: 1, unit: rf?.defaultPortion ?? 'porcja' };
              setIngredients([...ingredients, { foodId: s.id, qty: add.qty, unit: add.unit }]);
            }}
          />
        </div>
      )}

      {!isComposite && !item.ingredients && (
        <button className="btn small" style={{ justifySelf: 'start' }} onClick={() => setIngredients(ingredients)}>
          Dodaj składniki do tej pozycji
        </button>
      )}

      <div className="row">
        {def && (
          <button
            className="btn small"
            onClick={async () => {
              await app.saveOverride(def.override);
              setSaved(`Zapisano: ${def.description}. Ten opis da od teraz ten skład.`);
            }}
          >
            ★ Zapamiętaj jako moje
          </button>
        )}
        <span className="spacer" />
        <button className="btn small danger" onClick={onRemove}>
          Usuń pozycję
        </button>
      </div>
      {def && !saved && <div className="small muted">{def.description} — {Math.round(computeItem(db, item, calc).totals.kcal / Math.max(item.ingredients ? 1 : item.quantity, 1e-9))} kcal na porcję.</div>}
      {saved && (
        <div className="small" role="status">
          {saved}
        </div>
      )}
    </div>
  );
}
