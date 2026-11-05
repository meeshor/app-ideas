// Pomocnicze dla testów: baza z danych domyślnych.
import { buildDb } from './db.ts';
import { DEFAULT_DATA } from './defaults.ts';
import type { UserOverride } from './types.ts';

export function testDb(overrides: UserOverride[] = []) {
  return buildDb(DEFAULT_DATA, overrides);
}
