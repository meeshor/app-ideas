import { useMemo, useState } from 'react';
import { computeAll, computeItem, sumMacros } from '../../core/calculator.ts';
import { fmtNum } from '../../core/format.ts';
import { addDays, formatDatePl, guessMeal, localDate, localTime, MEAL_LABELS } from '../../core/meals.ts';
import { quickEntries } from '../../core/stats.ts';
import { CONFIG } from '../../core/config.ts';
import { MEALS, type ComputedItem, type LogEntry, type Meal, type ParsedItem } from '../../core/types.ts';
import { Bar, MacroLine } from '../components/common.tsx';
import { ItemEditor } from '../components/ItemEditor.tsx';
import { FoodEditor } from '../components/FoodEditor.tsx';
import { cloneItems, newId, useApp } from '../state.tsx';

function Lines({ c }: { c: ComputedItem }) {
  return (
    <ul className="pv-lines">
      {c.lines.map((l, i) => (
        <li key={i} className={l.approximate ? 'approx' : ''}>
          {l.explain}
        </li>
      ))}
      {c.removed.map((r) => (
        <li key={r}>bez: {r}</li>
      ))}
    </ul>
  );
}

function confidenceBadge(conf: number) {
  if (conf >= 0.95) return null;
  if (conf >= 0.75) return <span className="badge" title="Część wartości przybliżona (porcja ogólna lub mnożnik)">≈</span>;
  return (
    <span className="badge warn" title="Dopasowanie przybliżone — sprawdź, czy to właściwy produkt">
      literówka?
    </span>
  );
}

function Summary({ entries }: { entries: LogEntry[] }) {
  const { goals } = useApp();
  const t = sumMacros(entries.map((e) => e.totals));
  const left = goals.kcal - t.kcal;
  return (
    <section className="card" aria-label="Podsumowanie dnia">
      <div className="goal-kcal">
        <span className="big" data-testid="day-kcal">
          {Math.round(t.kcal)}
        </span>
        <span className="muted">/ {goals.kcal} kcal</span>
        <span className="spacer" />
        <span className={left < 0 ? 'badge warn' : 'badge ok'}>{left >= 0 ? `zostało ${Math.round(left)}` : `ponad o ${Math.round(-left)}`}</span>
      </div>
      <Bar value={t.kcal} max={goals.kcal} />
      <div className="macro-bars">
        {(
          [
            ['protein', 'Białko', 'B'],
            ['carbs', 'Węglowodany', 'W'],
            ['fat', 'Tłuszcz', 'T'],
          ] as const
        ).map(([k, name]) => (
          <div key={k}>
            <div className="label">
              <b>{name}</b>
              <span className="muted">
                {fmtNum(t[k], 0)}/{goals[k]} g
              </span>
            </div>
            <Bar value={t[k]} max={goals[k]} kind={k} />
          </div>
        ))}
      </div>
      {goals.source === 'default' && <p className="small muted" style={{ margin: '10px 0 0' }}>Cel orientacyjny 2000 kcal — uzupełnij profil w Ustawieniach, żeby go dopasować.</p>}
    </section>
  );
}

function EntryCard({ e }: { e: LogEntry }) {
  const app = useApp();
  const [open, setOpen] = useState(false);
  return (
    <li className="entry" data-testid="entry">
      <button onClick={() => setOpen(!open)} aria-expanded={open}>
        <span className="time">{e.time}</span>
        <span className="text">{e.text}</span>
        <b style={{ whiteSpace: 'nowrap' }}>{Math.round(e.totals.kcal)} kcal</b>
      </button>
      {open && (
        <div className="details">
          {e.computed.map((c, i) => (
            <div key={i}>
              <div className="small">
                <b>{c.label}</b> — {Math.round(c.totals.kcal)} kcal
              </div>
              <Lines c={c} />
            </div>
          ))}
          <MacroLine m={e.totals} />
          <div className="row">
            <select aria-label="Posiłek" value={e.meal} onChange={(ev) => app.saveEntry({ ...e, meal: ev.target.value as Meal, updatedAt: Date.now() })} style={{ width: 'auto' }}>
              {MEALS.map((m) => (
                <option key={m} value={m}>
                  {MEAL_LABELS[m]}
                </option>
              ))}
            </select>
            <button className="btn small" onClick={() => app.recompute(e)} title="Policz te same pozycje według aktualnej bazy">
              Przelicz ponownie
            </button>
            <span className="spacer" />
            <button className="btn small danger" onClick={() => app.deleteEntry(e.id)}>
              Usuń
            </button>
          </div>
        </div>
      )}
    </li>
  );
}

export function TodayView({ date, setDate }: { date: string; setDate: (d: string) => void }) {
  const app = useApp();
  const { db, parser, calc } = app;
  const [text, setText] = useState('');
  const [edited, setEdited] = useState<ParsedItem[] | null>(null);
  const [openIdx, setOpenIdx] = useState<number | null>(null);
  const [meal, setMeal] = useState<Meal | null>(null);
  const [newFood, setNewFood] = useState<string | null>(null);
  const today = localDate(new Date());

  const parsed = useMemo(() => (text.trim() ? parser.parse(text) : null), [text, parser]);
  const items = useMemo(() => edited ?? parsed?.items ?? [], [edited, parsed]);
  const preview = useMemo(() => computeAll(db, items, calc), [db, items, calc]);
  const autoMeal = parsed?.mealHint ?? guessMeal(new Date().getHours());
  const dayEntries = useMemo(() => app.entries.filter((e) => e.date === date).sort((a, b) => a.time.localeCompare(b.time) || a.createdAt - b.createdAt), [app.entries, date]);
  const quick = useMemo(() => quickEntries(app.entries, { recent: CONFIG.history.recentLimit, frequent: CONFIG.history.frequentLimit }), [app.entries]);

  const reset = () => {
    setText('');
    setEdited(null);
    setOpenIdx(null);
    setMeal(null);
  };
  const save = async () => {
    if (!items.length) return;
    const now = new Date();
    const entry: LogEntry = {
      id: newId(),
      date,
      time: localTime(now),
      meal: meal ?? autoMeal,
      text: text.trim(),
      items: cloneItems(items),
      computed: preview.computed,
      totals: preview.totals,
      createdAt: now.getTime(),
    };
    await app.saveEntry(entry);
    reset();
  };
  const reAdd = async (e: LogEntry) => {
    const now = new Date();
    const items2 = cloneItems(e.items);
    const { computed, totals } = computeAll(db, items2, calc);
    await app.saveEntry({ ...e, id: newId(), date, time: localTime(now), meal: guessMeal(now.getHours()), items: items2, computed, totals, createdAt: now.getTime(), updatedAt: undefined });
  };
  const setItem = (i: number, it: ParsedItem | null) => {
    const list = [...items];
    if (it) list[i] = it;
    else list.splice(i, 1);
    setEdited(list);
    if (!it) setOpenIdx(null);
  };

  return (
    <div>
      <div className="topbar">
        <h1>
          <span className="brand">Zjadłem</span>
        </h1>
        <div className="date-nav">
          <button className="btn ghost iconbtn" aria-label="Poprzedni dzień" onClick={() => setDate(addDays(date, -1))}>
            ‹
          </button>
          <button className="btn ghost label" onClick={() => setDate(today)} title="Wróć do dziś">
            {date === today ? 'Dziś' : formatDatePl(date)}
          </button>
          <button className="btn ghost iconbtn" aria-label="Następny dzień" disabled={date >= today} onClick={() => setDate(addDays(date, 1))}>
            ›
          </button>
        </div>
      </div>

      {app.storageError && <div className="notice">{app.storageError}</div>}

      <Summary entries={dayEntries} />

      <section className="card entry-box">
        <label htmlFor="what" className="sr-only">
          Co zjadłeś?
        </label>
        <textarea
          id="what"
          rows={2}
          value={text}
          placeholder="Co zjadłeś? np. duża bułka żytnia z szynką"
          autoComplete="off"
          onChange={(e) => {
            setText(e.target.value);
            setEdited(null);
            setOpenIdx(null);
          }}
          onKeyDown={(e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
              e.preventDefault();
              void save();
            }
          }}
        />
        {!text.trim() && (quick.recent.length > 0 || quick.frequent.length > 0) && (
          <div className="stack" style={{ marginTop: 10 }}>
            {quick.recent.length > 0 && (
              <div>
                <div className="small muted" style={{ marginBottom: 6 }}>
                  Ostatnie — dotknij, by dodać:
                </div>
                <div className="quick">
                  {quick.recent.map((q) => (
                    <button key={q.key} className="chip" onClick={() => reAdd(q.entry)} title={`${Math.round(q.kcal)} kcal`}>
                      {q.text} · {Math.round(q.kcal)}
                    </button>
                  ))}
                </div>
              </div>
            )}
            {quick.frequent.length > 0 && (
              <div>
                <div className="small muted" style={{ marginBottom: 6 }}>
                  Częste:
                </div>
                <div className="quick">
                  {quick.frequent.map((q) => (
                    <button key={q.key} className="chip" onClick={() => reAdd(q.entry)}>
                      {q.text} ×{q.count}
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {parsed && (
          <div className="preview" data-testid="preview">
            {items.length > 0 && (
              <ul className="pv-list">
                {items.map((it, i) => {
                  const c = preview.computed[i] ?? computeItem(db, it, calc);
                  const open = openIdx === i;
                  return (
                    <li key={i} className="pv-item" data-testid="preview-item">
                      <button className="pv-head" onClick={() => setOpenIdx(open ? null : i)} aria-expanded={open}>
                        <span className="name">
                          {it.quantity !== 1 && !it.ingredients ? `${fmtNum(it.quantity, 2)} × ` : ''}
                          {c.label}
                          {it.modifiers.length > 0 && <span className="muted small"> · {it.modifiers.join(', ')}</span>} {confidenceBadge(c.confidence)}
                          {it.edited && <span className="badge">zmienione</span>}
                        </span>
                        <span className="kcal">{Math.round(c.totals.kcal)} kcal</span>
                      </button>
                      <Lines c={c} />
                      {open && <ItemEditor item={it} onChange={(n) => setItem(i, n)} onRemove={() => setItem(i, null)} />}
                    </li>
                  );
                })}
              </ul>
            )}
            {parsed.unknown.length > 0 && (
              <div className="unknown-list" data-testid="unknown">
                <span className="small muted">Nie rozumiem:</span>
                {parsed.unknown.map((u, i) => (
                  <span key={i} className="row" style={{ gap: 4 }}>
                    <mark className="unknown">{u}</mark>
                    <button className="btn small" onClick={() => setNewFood(u)}>
                      + dodaj produkt
                    </button>
                  </span>
                ))}
              </div>
            )}
            <div className="pv-total">
              {items.length > 0 ? (
                <>
                  <span className="sum" data-testid="preview-total">
                    Razem {Math.round(preview.totals.kcal)} kcal
                  </span>
                  <MacroLine m={preview.totals} />
                </>
              ) : (
                <span className="muted">Nic nie rozpoznano.</span>
              )}
              <span className="spacer" />
              <select aria-label="Posiłek" value={meal ?? autoMeal} onChange={(e) => setMeal(e.target.value as Meal)} style={{ width: 'auto' }}>
                {MEALS.map((m) => (
                  <option key={m} value={m}>
                    {MEAL_LABELS[m]}
                  </option>
                ))}
              </select>
              <button className="btn primary" onClick={save} disabled={!items.length}>
                Zapisz
              </button>
            </div>
            <div className="small muted hint">Kliknij pozycję, żeby zmienić ilość, rozmiar, produkt lub skład. Enter zapisuje.</div>
          </div>
        )}
      </section>

      {MEALS.map((m) => {
        const list = dayEntries.filter((e) => e.meal === m);
        if (!list.length) return null;
        return (
          <section key={m} className="meal" aria-label={MEAL_LABELS[m]}>
            <h3>
              <span>{MEAL_LABELS[m]}</span>
              <span>{Math.round(sumMacros(list.map((e) => e.totals)).kcal)} kcal</span>
            </h3>
            <ul className="entries">
              {list.map((e) => (
                <EntryCard key={e.id} e={e} />
              ))}
            </ul>
          </section>
        );
      })}
      {dayEntries.length === 0 && <p className="empty">{date === today ? 'Dziś jeszcze nic nie zapisano.' : 'Brak wpisów tego dnia.'}</p>}

      <p className="disclaimer">Wartości to szacunki (typowo ±20–30% przy opisie słownym) i orientacyjne cele — nie porada medyczna.</p>

      {newFood !== null && <FoodEditor initialName={newFood} onClose={() => setNewFood(null)} />}
    </div>
  );
}
