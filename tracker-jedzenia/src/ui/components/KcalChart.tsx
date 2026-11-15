import { formatDatePl } from '../../core/meals.ts';
import type { SeriesDay } from '../../core/stats.ts';

/** Słupki kalorii z kolejnych dni i linia celu. Każdy słupek to przycisk otwierający dzień. */
export function KcalChart({ series, goal, today, onPick }: {
  series: readonly SeriesDay[];
  goal: number;
  today: string;
  onPick: (date: string) => void;
}) {
  const max = Math.max(goal * 1.25, ...series.map((d) => d.totals.kcal), 1);
  const goalPct = (goal / max) * 100;
  return (
    <div className="chart" data-testid="kcal-chart">
      <div className="chart-bars" style={{ ['--goal' as string]: `${goalPct}%` }}>
        {goal > 0 && <div className="chart-goal" aria-hidden="true" />}
        {series.map((d) => {
          const pct = (d.totals.kcal / max) * 100;
          const over = goal > 0 && d.totals.kcal > goal * 1.1;
          const label = `${d.date === today ? 'Dziś' : formatDatePl(d.date)}: ${d.logged ? `${Math.round(d.totals.kcal)} kcal` : 'brak wpisów'}`;
          return (
            <button
              key={d.date}
              className={`chart-bar${d.logged ? '' : ' empty'}${over ? ' over' : ''}${d.date === today ? ' today' : ''}`}
              onClick={() => onPick(d.date)}
              aria-label={label}
              title={label}
            >
              <span style={{ height: `${d.logged ? Math.max(pct, 2) : 0}%` }} />
            </button>
          );
        })}
      </div>
      <div className="chart-axis small muted" aria-hidden="true">
        <span>{shortDate(series[0]?.date)}</span>
        {goal > 0 && <span>cel {goal} kcal</span>}
        <span>{shortDate(series[series.length - 1]?.date)}</span>
      </div>
    </div>
  );
}

function shortDate(date: string | undefined): string {
  if (!date) return '';
  const [, m, d] = date.split('-');
  return `${Number(d)}.${m}`;
}
