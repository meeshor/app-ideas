import { test, expect } from '@playwright/test';
test('strona się ładuje', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'Zjadłem' })).toBeVisible();
});
