// IndexedDB (przez idb): wpisy dziennika, nadpisania użytkownika, ustawienia. Dane tylko w tej przeglądarce.

import { openDB, type DBSchema, type IDBPDatabase } from 'idb';
import type { LogEntry, Settings, UserOverride } from '../core/types.ts';

interface ZjadlemDB extends DBSchema {
  entries: { key: string; value: LogEntry; indexes: { byDate: string } };
  overrides: { key: string; value: UserOverride };
  kv: { key: string; value: unknown };
}

const DB_NAME = 'zjadlem';
let dbPromise: Promise<IDBPDatabase<ZjadlemDB>> | null = null;

function db(): Promise<IDBPDatabase<ZjadlemDB>> {
  dbPromise ??= openDB<ZjadlemDB>(DB_NAME, 1, {
    upgrade(d) {
      const entries = d.createObjectStore('entries', { keyPath: 'id' });
      entries.createIndex('byDate', 'date');
      d.createObjectStore('overrides', { keyPath: 'key' });
      d.createObjectStore('kv');
    },
  });
  return dbPromise;
}

export const repo = {
  async allEntries(): Promise<LogEntry[]> {
    return (await db()).getAll('entries');
  },
  async putEntry(e: LogEntry): Promise<void> {
    await (await db()).put('entries', e);
  },
  async deleteEntry(id: string): Promise<void> {
    await (await db()).delete('entries', id);
  },
  async allOverrides(): Promise<UserOverride[]> {
    return (await db()).getAll('overrides');
  },
  async putOverride(o: UserOverride): Promise<void> {
    await (await db()).put('overrides', o);
  },
  async deleteOverride(key: string): Promise<void> {
    await (await db()).delete('overrides', key);
  },
  async getSettings(): Promise<Settings | undefined> {
    return (await (await db()).get('kv', 'settings')) as Settings | undefined;
  },
  async putSettings(s: Settings): Promise<void> {
    await (await db()).put('kv', s, 'settings');
  },
  /** Zastępuje wszystkie dane (import). */
  async replaceAll(data: { settings: Settings; overrides: UserOverride[]; entries: LogEntry[] }): Promise<void> {
    const d = await db();
    const tx = d.transaction(['entries', 'overrides', 'kv'], 'readwrite');
    await Promise.all([tx.objectStore('entries').clear(), tx.objectStore('overrides').clear(), tx.objectStore('kv').clear()]);
    for (const e of data.entries) await tx.objectStore('entries').put(e);
    for (const o of data.overrides) await tx.objectStore('overrides').put(o);
    await tx.objectStore('kv').put(data.settings, 'settings');
    await tx.done;
  },
  async clearAll(): Promise<void> {
    const d = await db();
    const tx = d.transaction(['entries', 'overrides', 'kv'], 'readwrite');
    await Promise.all([tx.objectStore('entries').clear(), tx.objectStore('overrides').clear(), tx.objectStore('kv').clear(), tx.done]);
  },
};
