import { test, expect } from '@playwright/test';
import { waitForMagicLink, purgeAllMessages } from '../helpers/mailpit';

test('user signs in via magic link', async ({ page }) => {
  const email = `e2e-${Date.now()}@example.com`;
  await purgeAllMessages();

  // 1. Land on sign-in
  await page.goto('/');
  await expect(page.getByTestId('sign-in-title')).toBeVisible();

  // Visual regression guard: confirm theme colors are applied.
  // Phase 2 design system: title renders white on the navy hero.
  const titleColor = await page.evaluate(() => {
    const el = document.querySelector('[data-testid="sign-in-title"]');
    return el ? getComputedStyle(el as HTMLElement).color : null;
  });
  expect(titleColor).toBe('rgb(255, 255, 255)');

  // 2. Enter email and submit
  await page.getByTestId('sign-in-email').fill(email);
  await page.getByTestId('sign-in-submit').click();
  await expect(page.getByTestId('sign-in-sent')).toBeVisible({ timeout: 10_000 });

  // 3. Pull magic link from Mailpit
  const magicLink = await waitForMagicLink(email);
  expect(magicLink).toMatch(/\/auth\/v1\/verify\?token=/);

  // 4. Follow the magic link in the same browser. Supabase's verify endpoint
  //    redirects to the app URL with `#access_token=...&refresh_token=...` in
  //    the fragment; SessionContext's deep-link handler runs
  //    createSessionFromUrl which calls setSession.
  await page.goto(magicLink);

  // 5. After setSession runs, the auth gate redirects new (non-onboarded)
  //    users to /(onboarding)/goal (the new first step). The full
  //    onboarding-to-home path is covered by onboarding.spec.ts.
  await expect(page.getByTestId('step-title').last()).toHaveText("What's your goal?", {
    timeout: 15_000,
  });
});

test('renders apple and google sign-in buttons', async ({ page }) => {
  await page.goto('/');
  await page.getByTestId('sign-in-email').waitFor({ state: 'visible', timeout: 10_000 });
  await expect(page.getByTestId('sign-in-apple')).toBeVisible();
  await expect(page.getByTestId('sign-in-google')).toBeVisible();
});
