import { useRef, useState } from 'react';
import { makeBackup, parseBackup } from '../../core/backup.ts';
import { DEFAULT_SETTINGS, isValidProfile } from '../../core/goals.ts';
import { CONFIG } from '../../core/config.ts';
import type { Activity, GoalKind, Profile, Settings, SizeKey } from '../../core/types.ts';
import { useApp } from '../state.tsx';
import { NumberInput } from '../components/common.tsx';
import { localDate } from '../../core/meals.ts';

const ACTIVITY: Record<Activity, string> = {
  sedentary: 'siedzący (prawie bez ruchu)',
  light: 'lekka aktywność (1–3× w tyg.)',
  moderate: 'umiarkowana (3–5× w tyg.)',
  active: 'duża (6–7× w tyg.)',
  very_active: 'bardzo duża (praca fizyczna + sport)',
};
const GOAL: Record<GoalKind, string> = { lose: 'redukcja', maintain: 'utrzymanie', gain: 'masa' };
const DEFAULT_PROFILE: Profile = { sex: 'female', age: 35, heightCm: 168, weightKg: 68, activity: 'light', goal: 'maintain' };

export function SettingsView() {
  const app = useApp();
  const { settings, goals } = app;
  const [msg, setMsg] = useState<string | null>(null);
  const fileRef = useRef<HTMLInputElement>(null);
  const profile = settings.profile ?? DEFAULT_PROFILE;
  const set = (patch: Partial<Settings>) => app.saveSettings({ ...settings, ...patch });
  const setProfile = (patch: Partial<Profile>) => set({ profile: { ...profile, ...patch } });
  const splitSum = settings.split.carbs + settings.split.protein + settings.split.fat;

  const exportJson = () => {
    const backup = makeBackup({ settings, overrides: app.overrides, entries: app.entries });
    const blob = new Blob([JSON.stringify(backup, null, 1)], { type: 'application/json' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `zjadlem-${localDate(new Date())}.json`;
    a.click();
    setTimeout(() => URL.revokeObjectURL(a.href), 1000);
  };
  const importJson = async (file: File) => {
    const r = parseBackup(await file.text());
    if (!r.ok) return setMsg(r.error);
    const b = r.backup;
    if (!confirm(`Zastąpić wszystkie dane tym plikiem? (${b.entries.length} wpisów, ${b.overrides.length} własnych definicji)`)) return;
    await app.replaceAll({ settings: b.settings, overrides: b.overrides, entries: b.entries });
    setMsg(`Zaimportowano ${b.entries.length} wpisów i ${b.overrides.length} definicji.`);
  };

  return (
    <div>
      <div className="topbar">
        <h1>Ustawienia</h1>
      </div>

      <section className="card stack" aria-label="Profil">
        <h2>Profil i cel</h2>
        {!settings.profile && <p className="small muted">Profil nieuzupełniony — liczymy z celem 2000 kcal. Zmień dowolne pole, żeby zapisać profil.</p>}
        <div className="grid2">
          <label className="field">
            Płeć
            <select value={profile.sex} onChange={(e) => setProfile({ sex: e.target.value as Profile['sex'] })}>
              <option value="female">kobieta</option>
              <option value="male">mężczyzna</option>
            </select>
          </label>
          <label className="field">
            Wiek
            <NumberInput label="Wiek" value={profile.age} width="100%" onChange={(n) => setProfile({ age: n })} />
          </label>
          <label className="field">
            Wzrost (cm)
            <NumberInput label="Wzrost" value={profile.heightCm} width="100%" onChange={(n) => setProfile({ heightCm: n })} />
          </label>
          <label className="field">
            Waga (kg)
            <NumberInput label="Waga" value={profile.weightKg} width="100%" onChange={(n) => setProfile({ weightKg: n })} />
          </label>
        </div>
        <label className="field">
          Aktywność
          <select value={profile.activity} onChange={(e) => setProfile({ activity: e.target.value as Activity })}>
            {Object.entries(ACTIVITY).map(([k, l]) => (
              <option key={k} value={k}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <label className="field">
          Cel
          <select value={profile.goal} onChange={(e) => setProfile({ goal: e.target.value as GoalKind })}>
            {Object.entries(GOAL).map(([k, l]) => (
              <option key={k} value={k}>
                {l}
              </option>
            ))}
          </select>
        </label>
        {settings.profile && !isValidProfile(settings.profile) && <div className="notice">Sprawdź wiek, wzrost i wagę — wartości poza zakresem, liczymy z celem domyślnym.</div>}
        <table className="kv">
          <tbody>
            {goals.bmr !== null && (
              <tr>
                <td>Podstawowa przemiana (Mifflin-St Jeor)</td>
                <td>{goals.bmr} kcal</td>
              </tr>
            )}
            {goals.tdee !== null && (
              <tr>
                <td>× aktywność ({CONFIG.goals.activity[profile.activity]})</td>
                <td>{goals.tdee} kcal</td>
              </tr>
            )}
            <tr>
              <td>
                <b>Orientacyjny cel dzienny</b>
              </td>
              <td data-testid="goal-kcal">
                <b>{goals.kcal} kcal</b>
              </td>
            </tr>
            <tr>
              <td>Białko / węglowodany / tłuszcz</td>
              <td>
                {goals.protein} / {goals.carbs} / {goals.fat} g
              </td>
            </tr>
          </tbody>
        </table>
        <p className="small muted">To szacunek z ogólnego wzoru, nie zalecenie. Przy chorobach, ciąży, u dzieci i przy dużej redukcji skonsultuj cel z lekarzem lub dietetykiem.</p>
      </section>

      <section className="card stack" aria-label="Makro">
        <h2>Podział makro i cele ręczne</h2>
        <div className="grid4" style={{ gridTemplateColumns: 'repeat(3, 1fr)' }}>
          {(
            [
              ['protein', 'białko %'],
              ['carbs', 'węgl. %'],
              ['fat', 'tłuszcz %'],
            ] as const
          ).map(([k, l]) => (
            <label className="field" key={k}>
              {l}
              <NumberInput label={l} value={settings.split[k]} width="100%" onChange={(n) => set({ split: { ...settings.split, [k]: n } })} />
            </label>
          ))}
        </div>
        {splitSum !== 100 && <div className="small muted">Suma {splitSum}% — przeliczamy proporcjonalnie do 100%.</div>}
        <div className="small muted">Cele ręczne (puste = wyliczone):</div>
        <div className="grid4">
          {(
            [
              ['kcal', 'kcal'],
              ['protein', 'B g'],
              ['carbs', 'W g'],
              ['fat', 'T g'],
            ] as const
          ).map(([k, l]) => (
            <label className="field" key={k}>
              {l}
              <input
                type="text"
                inputMode="numeric"
                value={settings.manualGoals?.[k] ?? ''}
                onChange={(e) => {
                  const n = Number(e.target.value);
                  const next = { ...(settings.manualGoals ?? {}) };
                  if (!e.target.value || !Number.isFinite(n) || n <= 0) delete next[k];
                  else next[k] = n;
                  set({ manualGoals: Object.keys(next).length ? next : null });
                }}
              />
            </label>
          ))}
        </div>
      </section>

      <section className="card stack" aria-label="Rozmiary">
        <h2>Mnożniki rozmiarów</h2>
        <p className="small muted">Używane, gdy produkt nie ma własnych gramów dla rozmiaru (np. „ogromna” zawsze).</p>
        <div className="grid4" style={{ gridTemplateColumns: 'repeat(3, 1fr)' }}>
          {(['small', 'large', 'huge'] as SizeKey[]).map((s) => (
            <label className="field" key={s}>
              {app.db.modifiers.sizes[s].label}
              <NumberInput
                label={`mnożnik ${app.db.modifiers.sizes[s].label}`}
                value={settings.sizeMultipliers[s] ?? app.db.modifiers.sizes[s].multiplier}
                width="100%"
                onChange={(n) => set({ sizeMultipliers: { ...settings.sizeMultipliers, [s]: n } })}
              />
            </label>
          ))}
        </div>
      </section>

      <section className="card stack" aria-label="Wygląd">
        <h2>Wygląd</h2>
        <div className="seg" role="group" aria-label="Motyw">
          {(
            [
              ['auto', 'systemowy'],
              ['light', 'jasny'],
              ['dark', 'ciemny'],
            ] as const
          ).map(([k, l]) => (
            <button key={k} aria-pressed={settings.theme === k} onClick={() => set({ theme: k })}>
              {l}
            </button>
          ))}
        </div>
      </section>

      <section className="card stack" aria-label="Dane">
        <h2>Dane</h2>
        <p className="small muted">
          Wszystko jest tylko w tej przeglądarce ({app.entries.length} wpisów, {app.overrides.length} własnych definicji). Eksport to jedyna kopia zapasowa.
        </p>
        <div className="row">
          <button className="btn" onClick={exportJson}>
            Eksportuj JSON
          </button>
          <button className="btn" onClick={() => fileRef.current?.click()}>
            Importuj JSON…
          </button>
          <input
            ref={fileRef}
            type="file"
            accept="application/json,.json"
            hidden
            data-testid="import-file"
            onChange={(e) => {
              const f = e.target.files?.[0];
              if (f) void importJson(f);
              e.target.value = '';
            }}
          />
          <span className="spacer" />
          <button
            className="btn danger"
            onClick={async () => {
              if (confirm('Usunąć wszystkie wpisy, własne definicje i ustawienia? Tego nie da się cofnąć.')) {
                await app.resetAll();
                setMsg('Dane usunięte.');
              }
            }}
          >
            Resetuj dane
          </button>
        </div>
        {msg && (
          <div className="small" role="status">
            {msg}
          </div>
        )}
        <button className="btn small ghost" style={{ justifySelf: 'start' }} onClick={() => set({ ...DEFAULT_SETTINGS, profile: settings.profile })}>
          Przywróć domyślne ustawienia (bez profilu)
        </button>
      </section>
      <p className="disclaimer">
        Zjadłem — wersja {__APP_VERSION__}. Bez kont, bez serwera, bez AI: liczby pochodzą z bazy w aplikacji, a każdą możesz zmienić.
      </p>
    </div>
  );
}
