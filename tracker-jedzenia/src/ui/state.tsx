// Stan aplikacji: baza (domyślna + nadpisania), parser, ustawienia, wpisy. Cienka warstwa nad rdzeniem.

import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { buildDb, type FoodDb } from '../core/db.ts';
import { DEFAULT_DATA } from '../core/defaults.ts';
import { buildLexicon, type Lexicon } from '../core/lexicon.ts';
import { RuleParser } from '../core/parser.ts';
import { computeGoals, DEFAULT_SETTINGS, type Goals } from '../core/goals.ts';
import { computeAll, type CalcOptions } from '../core/calculator.ts';
import { repo } from '../storage/repo.ts';
import type { LogEntry, ParsedItem, Settings, UserOverride } from '../core/types.ts';

export interface AppState {
  ready: boolean;
  db: FoodDb;
  lex: Lexicon;
  parser: RuleParser;
  settings: Settings;
  goals: Goals;
  calc: CalcOptions;
  entries: LogEntry[];
  overrides: UserOverride[];
  saveEntry(e: LogEntry): Promise<void>;
  deleteEntry(id: string): Promise<void>;
  recompute(e: LogEntry): Promise<void>;
  saveOverride(o: UserOverride): Promise<void>;
  removeOverride(key: string): Promise<void>;
  saveSettings(s: Settings): Promise<void>;
  replaceAll(data: { settings: Settings; overrides: UserOverride[]; entries: LogEntry[] }): Promise<void>;
  resetAll(): Promise<void>;
  /** Błąd zapisu/odczytu IndexedDB (np. tryb prywatny). */
  storageError: string | null;
}

const Ctx = createContext<AppState | null>(null);

export function useApp(): AppState {
  const v = useContext(Ctx);
  if (!v) throw new Error('useApp poza AppProvider');
  return v;
}

export function AppProvider({ children }: { children: ReactNode }) {
  const [ready, setReady] = useState(false);
  const [entries, setEntries] = useState<LogEntry[]>([]);
  const [overrides, setOverrides] = useState<UserOverride[]>([]);
  const [settings, setSettings] = useState<Settings>(DEFAULT_SETTINGS);
  const [storageError, setStorageError] = useState<string | null>(null);

  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        const [e, o, s] = await Promise.all([repo.allEntries(), repo.allOverrides(), repo.getSettings()]);
        if (!alive) return;
        setEntries(e);
        setOverrides(o);
        if (s) setSettings({ ...DEFAULT_SETTINGS, ...s });
      } catch (err) {
        setStorageError(`Nie udało się otworzyć bazy w przeglądarce (${String(err)}). Dane nie będą zapisywane.`);
      } finally {
        if (alive) setReady(true);
      }
    })();
    return () => {
      alive = false;
    };
  }, []);

  const db = useMemo(() => buildDb(DEFAULT_DATA, [...overrides].sort((a, b) => a.updatedAt - b.updatedAt)), [overrides]);
  const lex = useMemo(() => buildLexicon(db), [db]);
  const parser = useMemo(() => new RuleParser(db, lex), [db, lex]);
  const goals = useMemo(() => computeGoals(settings), [settings]);
  const calc = useMemo<CalcOptions>(() => ({ sizeMultipliers: settings.sizeMultipliers }), [settings.sizeMultipliers]);

  const guard = useCallback(async (fn: () => Promise<void>) => {
    try {
      await fn();
    } catch (err) {
      setStorageError(`Błąd zapisu: ${String(err)}`);
    }
  }, []);

  const saveEntry = useCallback(
    async (e: LogEntry) => {
      setEntries((list) => [...list.filter((x) => x.id !== e.id), e]);
      await guard(() => repo.putEntry(e));
    },
    [guard],
  );
  const deleteEntry = useCallback(
    async (id: string) => {
      setEntries((list) => list.filter((x) => x.id !== id));
      await guard(() => repo.deleteEntry(id));
    },
    [guard],
  );
  const recompute = useCallback(
    async (e: LogEntry) => {
      const { computed, totals } = computeAll(db, e.items, calc);
      await saveEntry({ ...e, computed, totals, updatedAt: Date.now() });
    },
    [db, calc, saveEntry],
  );
  const saveOverride = useCallback(
    async (o: UserOverride) => {
      setOverrides((list) => [...list.filter((x) => x.key !== o.key), o]);
      await guard(() => repo.putOverride(o));
    },
    [guard],
  );
  const removeOverride = useCallback(
    async (key: string) => {
      setOverrides((list) => list.filter((x) => x.key !== key));
      await guard(() => repo.deleteOverride(key));
    },
    [guard],
  );
  const saveSettings = useCallback(
    async (s: Settings) => {
      setSettings(s);
      await guard(() => repo.putSettings(s));
    },
    [guard],
  );
  const replaceAll = useCallback(
    async (data: { settings: Settings; overrides: UserOverride[]; entries: LogEntry[] }) => {
      setEntries(data.entries);
      setOverrides(data.overrides);
      setSettings({ ...DEFAULT_SETTINGS, ...data.settings });
      await guard(() => repo.replaceAll(data));
    },
    [guard],
  );
  const resetAll = useCallback(async () => {
    setEntries([]);
    setOverrides([]);
    setSettings(DEFAULT_SETTINGS);
    await guard(() => repo.clearAll());
  }, [guard]);

  const value: AppState = {
    ready, db, lex, parser, settings, goals, calc, entries, overrides, storageError,
    saveEntry, deleteEntry, recompute, saveOverride, removeOverride, saveSettings, replaceAll, resetAll,
  };
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function newId(): string {
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
}

export function cloneItems(items: readonly ParsedItem[]): ParsedItem[] {
  return structuredClone(items as ParsedItem[]);
}
