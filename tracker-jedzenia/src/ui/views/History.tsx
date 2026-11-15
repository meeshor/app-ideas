import { useMemo, useState } from 'react';
import { fmtNum } from '../../core/format.ts';
import { formatDatePl, localDate } from '../../core/meals.ts';
import { dailySeries, daysOnTarget, summarizeDays, weekSummary } from '../../core/stats.ts';
import { useApp } from '../state.tsx';
import { Bar, MacroLine } from '../components/common.tsx';
import { KcalChart } from '../components/KcalChart.tsx';

export function HistoryView({ openDay }: { openDay: (d: string) => void }) {
  const { entries, goals } = useApp();
  const today = localDate(new Date());
  const days = useMemo(() => summarizeDays(entries), [entries]);
  const week = useMemo(() => weekSummary(entries, today), [entries, today]);
  const [range, setRange] = useState<14 | 30>(14);
  const series = useMemo(() => dailySeries(entries, today, range), [entries, today, range]);
  const target = daysOnTarget(series, goals.kcal);
  return (
    <div>
      <div className="topbar">
        <h1>Historia</h1>
      </div>
      <section className="card" aria-label="Podsumowanie tygodnia">
        <h2>Ostatnie 7 dni</h2>
        <p className="small muted" style={{ margin: '4px 0 10px' }}>
          Średnia z {week.daysWithEntries} {week.daysWithEntries === 1 ? 'dnia' : 'dni'} z wpisami (dni bez wpisów pomijane).
        </p>
        <div className="week">
          <div>
            <div className="v" data-testid="week-kcal">{Math.round(week.average.kcal)}</div>
            <div className="small muted">kcal / {goals.kcal}</div>
          </div>
          <div>
            <div className="v">{fmtNum(week.average.protein, 0)}</div>
            <div className="small muted">B g / {goals.protein}</div>
          </div>
          <div>
            <div className="v">{fmtNum(week.average.carbs, 0)}</div>
            <div className="small muted">W g / {goals.carbs}</div>
          </div>
          <div>
            <div className="v">{fmtNum(week.average.fat, 0)}</div>
            <div className="small muted">T g / {goals.fat}</div>
          </div>
        </div>
      </section>
      <section className="card" aria-label="Wykres kalorii">
        <div className="row-between">
          <h2>Kalorie dzień po dniu</h2>
          <div className="segmented" role="group" aria-label="Zakres wykresu">
            {([14, 30] as const).map((n) => (
              <button key={n} aria-pressed={range === n} onClick={() => setRange(n)}>
                {n} dni
              </button>
            ))}
          </div>
        </div>
        <KcalChart series={series} goal={goals.kcal} today={today} onPick={openDay} />
        <p className="small muted" data-testid="on-target">
          W celu (±10%): {target.onTarget} z {target.logged} {target.logged === 1 ? 'dnia' : 'dni'} z wpisami.
        </p>
      </section>
      <section className="card" aria-label="Dni">
        {days.length === 0 ? (
          <p className="empty">Brak wpisów.</p>
        ) : (
          <ul className="list">
            {days.slice(0, 60).map((d) => (
              <li key={d.date}>
                <button onClick={() => openDay(d.date)}>
                  <span className="name">
                    {d.date === today ? 'Dziś' : formatDatePl(d.date)} <span className="small muted">· {d.count} wpis{d.count === 1 ? '' : d.count < 5 ? 'y' : 'ów'}</span>
                    <br />
                    <MacroLine m={d.totals} />
                    <div className="daybar">
                      <Bar value={d.totals.kcal} max={goals.kcal} />
                    </div>
                  </span>
                  <b>{Math.round(d.totals.kcal)} kcal</b>
                </button>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
