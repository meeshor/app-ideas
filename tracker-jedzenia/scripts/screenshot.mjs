// Zrzut ekranu „Dziś” na szerokości telefonu → docs/screenshot-dzis.png
// Wymaga działającego `npm run preview` na porcie 4173. Uruchomienie: node scripts/screenshot.mjs [jasny|ciemny]
import { chromium } from '@playwright/test';

const dark = process.argv[2] === 'ciemny';
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 390, height: 1240 }, deviceScaleFactor: 2, colorScheme: dark ? 'dark' : 'light', isMobile: true, hasTouch: true });
await page.goto('http://localhost:4173/');
const input = page.getByPlaceholder('Co zjadłeś?');
for (const t of ['owsianka z bananem', '2 jajka i kawa z mlekiem', 'schabowy z ziemniakami i surówką']) {
  await input.fill(t);
  await page.getByTestId('preview-item').first().waitFor();
  await page.getByRole('button', { name: 'Zapisz', exact: true }).click();
}
await input.fill('duża bułka żytnia z szynką, bez masła i kawior');
await page.getByTestId('preview-item').first().waitFor();
await input.blur();
await page.screenshot({ path: new URL(`../docs/screenshot-dzis${dark ? '-ciemny' : ''}.png`, import.meta.url).pathname });
await browser.close();
console.log('zapisano zrzut');
