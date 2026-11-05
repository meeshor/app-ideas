// Eksport i import danych użytkownika (JSON). Walidacja bez zależności zewnętrznych.

import type { LogEntry, Settings, UserOverride } from './types.ts';

export const BACKUP_APP = 'zjadlem';
export const BACKUP_VERSION = 1;

export interface Backup {
  app: typeof BACKUP_APP;
  version: number;
  exportedAt: string;
  settings: Settings;
  overrides: UserOverride[];
  entries: LogEntry[];
}

export function makeBackup(data: { settings: Settings; overrides: UserOverride[]; entries: LogEntry[] }, now = new Date()): Backup {
  return { app: BACKUP_APP, version: BACKUP_VERSION, exportedAt: now.toISOString(), ...data };
}

export type ParseBackupResult = { ok: true; backup: Backup } | { ok: false; error: string };

const isObj = (x: unknown): x is Record<string, unknown> => !!x && typeof x === 'object' && !Array.isArray(x);

export function parseBackup(json: string): ParseBackupResult {
  let raw: unknown;
  try {
    raw = JSON.parse(json);
  } catch {
    return { ok: false, error: 'To nie jest poprawny plik JSON.' };
  }
  if (!isObj(raw) || raw.app !== BACKUP_APP) return { ok: false, error: 'To nie jest eksport z aplikacji Zjadłem.' };
  if (typeof raw.version !== 'number' || raw.version > BACKUP_VERSION) return { ok: false, error: 'Nieobsługiwana wersja pliku eksportu.' };
  if (!isObj(raw.settings)) return { ok: false, error: 'Brak ustawień w pliku.' };
  if (!Array.isArray(raw.overrides) || !Array.isArray(raw.entries)) return { ok: false, error: 'Brak listy wpisów lub definicji.' };
  for (const e of raw.entries) {
    if (!isObj(e) || typeof e.id !== 'string' || typeof e.date !== 'string' || typeof e.text !== 'string' || !Array.isArray(e.items) || !isObj(e.totals))
      return { ok: false, error: 'Uszkodzony wpis w dzienniku.' };
  }
  for (const o of raw.overrides) {
    if (!isObj(o) || typeof o.key !== 'string' || typeof o.id !== 'string' || !['food', 'dish', 'modifiers'].includes(String(o.kind)))
      return { ok: false, error: 'Uszkodzona definicja użytkownika.' };
  }
  return { ok: true, backup: raw as unknown as Backup };
}
