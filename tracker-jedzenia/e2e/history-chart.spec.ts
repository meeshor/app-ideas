import { test, expect, type Page } from '@playwright/test';

const input = (page: Page) => page.getByPlaceholder('Co zjadłeś?');
const nav = (page: Page, name: string) => page.getByRole('navigation').getByRole('button', { name }).click();

test('historia: wykres kalorii z zakresem 14/30 dni i przejściem do dnia', async ({ page }) => {
  await page.goto('/');
  await input(page).fill('2 jajka');
  await expect(page.getByTestId('preview-item').first()).toBeVisible();
  await page.getByRole('button', { name: 'Zapisz', exact: true }).click();
  await expect(page.getByTestId('day-kcal')).not.toHaveText('0');
  const kcal = await page.getByTestId('day-kcal').textContent();

  await nav(page, 'Historia');
  const chart = page.getByTestId('kcal-chart');
  await expect(chart.getByRole('button')).toHaveCount(14);
  await expect(chart.getByRole('button', { name: `Dziś: ${kcal} kcal` })).toBeVisible();
  await expect(page.getByTestId('on-target')).toContainText('z 1 dnia');

  await page.getByRole('button', { name: '30 dni' }).click();
  await expect(chart.getByRole('button')).toHaveCount(30);
  await expect(page.getByRole('button', { name: '30 dni' })).toHaveAttribute('aria-pressed', 'true');

  await chart.getByRole('button', { name: /^Dziś:/ }).click();
  await expect(page.getByTestId('entry')).toHaveCount(1);
});
