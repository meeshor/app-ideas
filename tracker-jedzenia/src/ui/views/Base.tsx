import { useMemo, useState } from 'react';
import { computeItem } from '../../core/calculator.ts';
import { overrideKey } from '../../core/db.ts';
import { keyOf } from '../../core/text.ts';
import { DEFAULT_DATA } from '../../core/defaults.ts';
import type { ModifiersData } from '../../core/types.ts';
import { useApp } from '../state.tsx';
import { DishEditor, FoodEditor } from '../components/FoodEditor.tsx';
import { NumberInput } from '../components/common.tsx';

type Tab = 'foods' | 'dishes' | 'modifiers';

function Origin({ o }: { o: string | undefined }) {
  if (o === 'user') return <span className="badge ok">moje</span>;
  if (o === 'changed') return <span className="badge warn">zmienione</span>;
  return null;
}

function ModifiersEditor() {
  const app = useApp();
  const m = app.db.modifiers;
  const [draft, setDraft] = useState<ModifiersData>(structuredClone(m));
  const changed = app.db.modifiers !== DEFAULT_DATA.modifiers;
  return (
    <div className="stack">
      <p className="small muted">
        Mnożniki rozmiarów („mała”, „duża”, „ogromna”) zmienisz w Ustawieniach. Tu: modyfikatory ilości i wartości zapasowe jednostek (gdy produkt nie ma własnej porcji).
      </p>
      <h3>Modyfikatory ilości</h3>
      <table className="kv">
        <tbody>
          {draft.amounts.map((a, i) => (
            <tr key={a.id}>
              <td>
                <b>{a.label}</b> <span className="small muted">({a.forms.slice(0, 4).join(', ')}…)</span>
              </td>
              <td>
                ×{' '}
                <NumberInput label={`mnożnik ${a.label}`} value={a.multiplier} onChange={(n) => setDraft({ ...draft, amounts: draft.amounts.map((x, j) => (j === i ? { ...x, multiplier: n } : x)) })} />
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      <h3>Jednostki (wartości zapasowe)</h3>
      <table className="kv">
        <tbody>
          {Object.entries(draft.units)
            .filter(([, u]) => u.fallbackGrams !== undefined || (u.ml !== undefined && u.label !== 'ml' && u.label !== 'l'))
            .map(([k, u]) => (
              <tr key={k}>
                <td>{u.label}</td>
                <td>
                  <NumberInput
                    label={`${u.label} — ${u.ml !== undefined ? 'ml' : 'g'}`}
                    value={u.ml ?? u.fallbackGrams ?? 0}
                    onChange={(n) => setDraft({ ...draft, units: { ...draft.units, [k]: u.ml !== undefined ? { ...u, ml: n } : { ...u, fallbackGrams: n } } })}
                  />{' '}
                  {u.ml !== undefined ? 'ml' : 'g'}
                </td>
              </tr>
            ))}
        </tbody>
      </table>
      <div className="row">
        <button className="btn primary" onClick={() => app.saveOverride({ key: overrideKey('modifiers', 'all'), kind: 'modifiers', id: 'all', data: draft, isNew: false, updatedAt: Date.now() })}>
          Zapisz modyfikatory
        </button>
        {changed && (
          <button
            className="btn"
            onClick={async () => {
              await app.removeOverride(overrideKey('modifiers', 'all'));
              setDraft(structuredClone(DEFAULT_DATA.modifiers));
            }}
          >
            Przywróć domyślne
          </button>
        )}
      </div>
    </div>
  );
}

export function BaseView() {
  const app = useApp();
  const { db, calc } = app;
  const [tab, setTab] = useState<Tab>('foods');
  const [q, setQ] = useState('');
  const [edit, setEdit] = useState<{ kind: 'food' | 'dish'; id?: string } | null>(null);
  const qk = keyOf(q);

  const foods = useMemo(
    () =>
      [...db.foods.values()]
        .filter((f) => !qk || keyOf([f.name, ...(f.aliases ?? [])].join(' ')).includes(qk))
        .sort((a, b) => (a.category ?? '').localeCompare(b.category ?? '', 'pl') || a.name.localeCompare(b.name, 'pl')),
    [db, qk],
  );
  const dishes = useMemo(() => [...db.dishes.values()].filter((d) => !qk || keyOf([d.name, ...(d.aliases ?? [])].join(' ')).includes(qk)).sort((a, b) => a.name.localeCompare(b.name, 'pl')), [db, qk]);

  return (
    <div>
      <div className="topbar">
        <h1>Baza</h1>
        {tab !== 'modifiers' && (
          <button className="btn small" onClick={() => setEdit({ kind: tab === 'foods' ? 'food' : 'dish' })}>
            + {tab === 'foods' ? 'produkt' : 'danie'}
          </button>
        )}
      </div>
      <div className="row" style={{ marginBottom: 12 }}>
        <div className="seg" role="group" aria-label="Rodzaj">
          {(
            [
              ['foods', `Produkty (${db.foods.size})`],
              ['dishes', `Dania (${db.dishes.size})`],
              ['modifiers', 'Modyfikatory'],
            ] as const
          ).map(([k, l]) => (
            <button key={k} aria-pressed={tab === k} onClick={() => setTab(k)}>
              {l}
            </button>
          ))}
        </div>
      </div>
      {tab !== 'modifiers' && <input type="search" placeholder="Szukaj…" value={q} onChange={(e) => setQ(e.target.value)} aria-label="Szukaj w bazie" style={{ marginBottom: 8 }} />}
      <div className="card">
        {tab === 'foods' && (
          <ul className="list">
            {foods.map((f) => (
              <li key={f.id}>
                <button onClick={() => setEdit({ kind: 'food', id: f.id })}>
                  <span className="name">
                    {f.name} {f.parentId && <span className="badge">wariant</span>} <Origin o={db.origin.get(`food:${f.id}`)} />
                    <br />
                    <span className="small muted">{f.category}</span>
                  </span>
                  <span className="small muted">{f.per100 ? `${f.per100.kcal} kcal/100 g` : 'dziedziczy'}</span>
                </button>
              </li>
            ))}
          </ul>
        )}
        {tab === 'dishes' && (
          <ul className="list">
            {dishes.map((d) => {
              const c = computeItem(db, { kind: 'dish', matchedId: d.id, quantity: 1, unit: null, size: null, modifiers: [], factor: 1, confidence: 1, fragment: '', changes: [] }, calc);
              return (
                <li key={d.id}>
                  <button onClick={() => setEdit({ kind: 'dish', id: d.id })}>
                    <span className="name">
                      {d.name} <Origin o={db.origin.get(`dish:${d.id}`)} />
                      <br />
                      <span className="small muted">{d.ingredients.map((i) => db.foods.get(i.foodId)?.name ?? i.foodId).join(' + ')}</span>
                    </span>
                    <span className="small muted">{Math.round(c.totals.kcal)} kcal</span>
                  </button>
                </li>
              );
            })}
          </ul>
        )}
        {tab === 'modifiers' && <ModifiersEditor />}
      </div>
      <p className="disclaimer">Wartości domyślne są przybliżone (typowe wartości tabel składu żywności, niezweryfikowane). Twoje zmiany mają pierwszeństwo i można je przywrócić.</p>
      {edit?.kind === 'food' && <FoodEditor foodId={edit.id} onClose={() => setEdit(null)} />}
      {edit?.kind === 'dish' && <DishEditor dishId={edit.id} onClose={() => setEdit(null)} />}
    </div>
  );
}
