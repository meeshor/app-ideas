import { useEffect, useRef, useState, type ReactNode } from 'react';
import type { Macros } from '../../core/types.ts';
import { fmtNum } from '../../core/format.ts';
import { useApp } from '../state.tsx';
import { searchNames, type Suggestion } from '../../core/search.ts';

export function Bar({ value, max, kind }: { value: number; max: number; kind?: string }) {
  const pct = max > 0 ? Math.min(100, (value / max) * 100) : 0;
  const over = max > 0 && value > max * 1.05;
  return (
    <div className={`bar ${kind ?? ''} ${over ? 'over' : ''}`} role="progressbar" aria-valuenow={Math.round(value)} aria-valuemin={0} aria-valuemax={Math.round(max)}>
      <span style={{ width: `${pct}%` }} />
    </div>
  );
}

export function MacroLine({ m }: { m: Macros }) {
  return (
    <span className="macros-inline">
      <span className="dot" style={{ background: 'var(--protein)' }} />B {fmtNum(m.protein, 0)} g ·{' '}
      <span className="dot" style={{ background: 'var(--carbs)' }} />W {fmtNum(m.carbs, 0)} g ·{' '}
      <span className="dot" style={{ background: 'var(--fat)' }} />T {fmtNum(m.fat, 0)} g
    </span>
  );
}

export function Modal({ title, onClose, children }: { title: string; onClose: () => void; children: ReactNode }) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', onKey);
    ref.current?.querySelector<HTMLElement>('input, select, textarea, button')?.focus();
    return () => window.removeEventListener('keydown', onKey);
  }, [onClose]);
  return (
    <div className="modal-backdrop" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal" role="dialog" aria-modal="true" aria-label={title} ref={ref}>
        <header>
          <h2>{title}</h2>
          <button className="btn ghost iconbtn" onClick={onClose} aria-label="Zamknij">
            ✕
          </button>
        </header>
        {children}
      </div>
    </div>
  );
}

/** Pole wyszukiwania produktu/dania z listą podpowiedzi. */
export function FoodPicker({
  onPick,
  kinds = ['food', 'dish'],
  placeholder = 'Szukaj produktu…',
  initial = '',
  label,
}: {
  onPick: (s: Suggestion) => void;
  kinds?: ('food' | 'dish')[];
  placeholder?: string;
  initial?: string;
  label?: string;
}) {
  const { db, lex } = useApp();
  const [q, setQ] = useState(initial);
  const results = q.trim().length >= 2 ? searchNames(db, lex, q, 8, kinds) : [];
  return (
    <div className="suggest">
      <input type="search" value={q} onChange={(e) => setQ(e.target.value)} placeholder={placeholder} aria-label={label ?? placeholder} />
      {results.length > 0 && (
        <ul>
          {results.map((r) => (
            <li key={`${r.kind}:${r.id}`}>
              <button
                type="button"
                onClick={() => {
                  onPick(r);
                  setQ('');
                }}
              >
                {r.name} {r.kind === 'dish' && <span className="badge">danie</span>}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

export function NumberInput({ value, onChange, step = 1, min = 0, label, width }: { value: number; onChange: (n: number) => void; step?: number; min?: number; label: string; width?: string }) {
  const [text, setText] = useState(String(value).replace('.', ','));
  useEffect(() => {
    setText((t) => (Number(t.replace(',', '.')) === value ? t : String(value).replace('.', ',')));
  }, [value]);
  return (
    <input
      type="text"
      inputMode="decimal"
      aria-label={label}
      value={text}
      style={{ width: width ?? '5.5em' }}
      onChange={(e) => {
        setText(e.target.value);
        const n = Number(e.target.value.replace(',', '.'));
        if (Number.isFinite(n) && n >= min) onChange(n);
      }}
      onBlur={() => setText(String(value).replace('.', ','))}
      data-step={step}
    />
  );
}
