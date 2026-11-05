import { test, expect, type Page } from '@playwright/test';
import { readFileSync } from 'node:fs';

const input = (page: Page) => page.getByPlaceholder('Co zjadłeś?');
const nav = (page: Page, name: string) => page.getByRole('navigation').getByRole('button', { name }).click();
async function add(page: Page, text: string) {
  await input(page).fill(text);
  await expect(page.getByTestId('preview-item').first()).toBeVisible();
  await page.getByRole('button', { name: 'Zapisz', exact: true }).click();
  await expect(input(page)).toHaveValue('');
}

test.beforeEach(async ({ page }) => {
  await page.goto('/');
  await expect(input(page)).toBeVisible();
});

test('„Zapamiętaj jako moje”: poprawiony skład wraca przy tym samym opisie', async ({ page }) => {
  await input(page).fill('bułka z szynką');
  await page.getByTestId('preview-item').getByRole('button').first().click();
  const ed = page.getByTestId('item-editor');
  await ed.getByLabel('Ilość: szynka').fill('3');
  await ed.getByRole('button', { name: 'Usuń składnik masło' }).click();
  await expect(page.getByTestId('preview')).toContainText('szynka 3 plastry = 45 g');
  await ed.getByRole('button', { name: /Zapamiętaj jako moje/ }).click();
  await expect(ed.getByRole('status')).toContainText('Twoja wersja dania „bułka z szynką”');
  await input(page).fill('');
  await input(page).fill('2 bułki z szynką');
  await expect(page.getByTestId('preview')).toContainText('szynka 6 plastrów = 90 g');
  await expect(page.getByTestId('preview')).not.toContainText('masło');
  // w Bazie danie oznaczone i przywracalne
  await nav(page, 'Baza');
  await page.getByRole('button', { name: /Dania/ }).click();
  await page.getByLabel('Szukaj w bazie').fill('bułka z szynką');
  await page.getByRole('button', { name: /^bułka z szynką zmienione/ }).click();
  await page.getByRole('dialog').getByRole('button', { name: 'Przywróć domyślne' }).click();
  await nav(page, 'Dziś');
  await input(page).fill('bułka z szynką');
  await expect(page.getByTestId('preview')).toContainText('masło 5 g');
});

test('edycja produktu w bazie zmienia wyliczenie, przywrócenie cofa', async ({ page }) => {
  await nav(page, 'Baza');
  await page.getByLabel('Szukaj w bazie').fill('bułka pszenna');
  await page.getByRole('button', { name: /bułka pszenna/ }).first().click();
  const d = page.getByRole('dialog');
  await d.getByLabel('gramy porcji sztuka').fill('100');
  await d.getByRole('button', { name: 'Zapisz' }).click();
  await expect(page.getByRole('button', { name: /bułka pszenna.*zmienione/ })).toBeVisible();
  await nav(page, 'Dziś');
  await input(page).fill('bułka');
  await expect(page.getByTestId('preview')).toContainText('bułka pszenna 100 g → 290 kcal');
  await nav(page, 'Baza');
  await page.getByLabel('Szukaj w bazie').fill('bułka pszenna');
  await page.getByRole('button', { name: /bułka pszenna/ }).first().click();
  await page.getByRole('dialog').getByRole('button', { name: 'Przywróć domyślne' }).click();
  await nav(page, 'Dziś');
  await input(page).fill('bułka');
  await expect(page.getByTestId('preview')).toContainText('bułka pszenna 60 g → 174 kcal');
});

test('profil → cel Mifflin-St Jeor; historia ze średnią; szybkie ponawianie', async ({ page }) => {
  await nav(page, 'Ustawienia');
  await page.getByRole('combobox').first().selectOption('male');
  await page.getByLabel('Wiek').fill('30');
  await page.getByLabel('Wzrost').fill('180');
  await page.getByLabel('Waga').fill('80');
  await page.getByRole('combobox').nth(1).selectOption('moderate');
  await expect(page.getByTestId('goal-kcal')).toHaveText('2760 kcal'); // 1780 × 1,55 = 2759 → 2760
  await nav(page, 'Dziś');
  await expect(page.getByText('/ 2760 kcal')).toBeVisible();
  await add(page, 'kawa z mlekiem');
  await add(page, '2 jajka');
  // szybkie ponawianie
  await page.getByRole('button', { name: /^kawa z mlekiem · 20/ }).click();
  await expect(page.getByTestId('entry')).toHaveCount(3);
  await expect(page.getByTestId('day-kcal')).toHaveText('194');
  await nav(page, 'Historia');
  await expect(page.getByTestId('week-kcal')).toHaveText('194');
  await page.getByRole('button', { name: /Dziś · 3 wpisy/ }).click();
  await expect(page.getByTestId('entry')).toHaveCount(3);
});

test('eksport i import JSON', async ({ page }) => {
  await add(page, 'banan');
  await nav(page, 'Ustawienia');
  const [download] = await Promise.all([page.waitForEvent('download'), page.getByRole('button', { name: 'Eksportuj JSON' }).click()]);
  const path = await download.path();
  const json = JSON.parse(readFileSync(path!, 'utf8'));
  expect(json.app).toBe('zjadlem');
  expect(json.entries).toHaveLength(1);
  page.on('dialog', (d) => d.accept());
  await page.getByRole('button', { name: 'Resetuj dane' }).click();
  await expect(page.getByText(/0 wpisów/)).toBeVisible();
  await page.getByTestId('import-file').setInputFiles(path!);
  await expect(page.getByRole('status')).toContainText('Zaimportowano 1 wpisów');
  await nav(page, 'Dziś');
  await expect(page.getByTestId('entry')).toHaveCount(1);
});

test('PWA: manifest i działanie offline po pierwszym wczytaniu', async ({ page, context }) => {
  const manifest = await (await page.request.get('/manifest.webmanifest')).json();
  expect(manifest.name).toContain('Zjadłem');
  await page.evaluate(async () => {
    await navigator.serviceWorker.ready;
  });
  await page.reload(); // strona pod kontrolą service workera
  await expect.poll(() => page.evaluate(() => !!navigator.serviceWorker.controller)).toBe(true);
  await context.setOffline(true);
  await page.reload();
  await expect(input(page)).toBeVisible();
  await input(page).fill('jajecznica');
  await expect(page.getByTestId('preview-total')).toContainText('kcal');
  await context.setOffline(false);
});
