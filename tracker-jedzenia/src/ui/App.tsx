import { useEffect, useState } from 'react';
import { localDate } from '../core/meals.ts';
import { AppProvider, useApp } from './state.tsx';
import { TodayView } from './views/Today.tsx';
import { HistoryView } from './views/History.tsx';
import { BaseView } from './views/Base.tsx';
import { SettingsView } from './views/Settings.tsx';

type Tab = 'today' | 'history' | 'base' | 'settings';
const TABS: { id: Tab; label: string; icon: string }[] = [
  { id: 'today', label: 'Dziś', icon: 'M4 12h16M12 4v16' },
  { id: 'history', label: 'Historia', icon: 'M12 7v5l3 2M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0z' },
  { id: 'base', label: 'Baza', icon: 'M4 6h16M4 12h16M4 18h10' },
  { id: 'settings', label: 'Ustawienia', icon: 'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z' },
];

function readTab(): Tab {
  const h = location.hash.replace('#', '');
  return TABS.some((t) => t.id === h) ? (h as Tab) : 'today';
}

function Shell() {
  const app = useApp();
  const [tab, setTab] = useState<Tab>(readTab);
  const [date, setDate] = useState(() => localDate(new Date()));

  useEffect(() => {
    const onHash = () => setTab(readTab());
    window.addEventListener('hashchange', onHash);
    return () => window.removeEventListener('hashchange', onHash);
  }, []);
  useEffect(() => {
    const root = document.documentElement;
    if (app.settings.theme === 'auto') root.removeAttribute('data-theme');
    else root.setAttribute('data-theme', app.settings.theme);
  }, [app.settings.theme]);

  const go = (t: Tab) => {
    if (t !== tab) history.replaceState(null, '', t === 'today' ? location.pathname : `#${t}`);
    setTab(t);
    window.scrollTo(0, 0);
  };

  if (!app.ready) return <main className="app"><p className="empty">Wczytywanie…</p></main>;
  return (
    <>
      <main className="app">
        {tab === 'today' && <TodayView date={date} setDate={setDate} />}
        {tab === 'history' && (
          <HistoryView
            openDay={(d) => {
              setDate(d);
              go('today');
            }}
          />
        )}
        {tab === 'base' && <BaseView />}
        {tab === 'settings' && <SettingsView />}
      </main>
      <nav className="tabbar" aria-label="Nawigacja">
        {TABS.map((t) => (
          <button key={t.id} aria-current={tab === t.id ? 'page' : undefined} onClick={() => go(t.id)}>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <path d={t.icon} />
            </svg>
            {t.label}
          </button>
        ))}
      </nav>
    </>
  );
}

export function App() {
  return (
    <AppProvider>
      <Shell />
    </AppProvider>
  );
}
