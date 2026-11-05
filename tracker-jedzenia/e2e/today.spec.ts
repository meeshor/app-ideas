import { test, expect, type Page } from '@playwright/test';

const input = (page: Page) => page.getByPlaceholder('Co zjadłeś?');

test.beforeEach(async ({ page }) => {
  await page.goto('/');
  await expect(input(page)).toBeVisible();
});

test('M3: „duża bułka żytnia z szynką” → podgląd z rozbiciem → zapis → suma dnia', async ({ page }) => {
  await input(page).fill('duża bułka żytnia z szynką');
  const preview = page.getByTestId('preview');
  await expect(preview.getByTestId('preview-item')).toHaveCount(1);
  await expect(preview).toContainText('bułka z szynką (bułka żytnia)');
  await expect(preview).toContainText('bułka żytnia 1 szt. (duża: 80 g) = 80 g → 200 kcal');
  await expect(preview).toContainText('masło 5 g → 37 kcal');
  const total = await preview.getByTestId('preview-total').textContent();
  const kcal = Number(total!.match(/(\d+) kcal/)![1]);
  expect(kcal).toBeGreaterThan(250);

  await page.getByRole('button', { name: 'Zapisz', exact: true }).click();
  await expect(page.getByTestId('entry')).toHaveCount(1);
  await expect(page.getByTestId('day-kcal')).toHaveText(String(kcal));
  await expect(input(page)).toHaveValue('');

  // trwałość: po przeładowaniu wpis jest w IndexedDB
  await page.reload();
  await expect(page.getByTestId('entry')).toHaveCount(1);
  await expect(page.getByTestId('day-kcal')).toHaveText(String(kcal));
});

test('edycja pozycji w podglądzie zmienia wynik; Enter zapisuje', async ({ page }) => {
  await input(page).fill('jajko');
  await expect(page.getByTestId('preview-total')).toHaveText('Razem 77 kcal');
  await page.getByTestId('preview-item').getByRole('button').first().click();
  const qty = page.getByTestId('item-editor').getByLabel('Ilość');
  await qty.fill('3');
  await expect(page.getByTestId('preview-total')).toHaveText('Razem 231 kcal');
  await input(page).focus();
  await page.keyboard.press('Enter');
  await expect(page.getByTestId('day-kcal')).toHaveText('231');
});

test('niezrozumiany fragment jest podświetlony i można dodać produkt', async ({ page }) => {
  await input(page).fill('bułka i kawior');
  await expect(page.getByTestId('unknown')).toContainText('kawior');
  await page.getByRole('button', { name: '+ dodaj produkt' }).click();
  const dialog = page.getByRole('dialog');
  await expect(dialog.getByLabel('Nazwa')).toHaveValue('kawior');
  await dialog.getByLabel('kcal', { exact: true }).fill('250');
  await dialog.getByRole('button', { name: 'Zapisz' }).click();
  await expect(dialog).toBeHidden();
  // tekst przeliczony z nowym produktem: brak niezrozumianych
  await expect(page.getByTestId('unknown')).toHaveCount(0);
  await expect(page.getByTestId('preview-item')).toHaveCount(2);
});
