import { test, expect } from '@playwright/test';
import { waitForMagicLink, purgeAllMessages } from '../helpers/mailpit';

test('new user completes onboarding and lands on home', async ({ page }) => {
  const email = `onboard-${Date.now()}@example.com`;
  await purgeAllMessages();

  // Sign up via magic link
  await page.goto('/');
  await expect(page.getByTestId('sign-in-title')).toBeVisible();
  await page.getByTestId('sign-in-email').fill(email);
  await page.getByTestId('sign-in-submit').click();
  await expect(page.getByTestId('sign-in-sent')).toBeVisible();

  const magicLink = await waitForMagicLink(email);
  await page.goto(magicLink);

  // Phase 2 onboarding order: Goal → Identity → Roles → About.
  await expect(page.getByTestId('step-title').last()).toHaveText("What's your goal?", {
    timeout: 15_000,
  });

  // Step 1: Goal (free-form text)
  await page
    .getByTestId('goal-text')
    .fill('Connecting with other builders working on AI products.');
  await page.getByTestId('goal-next').click();

  // Step 2: Identity
  await expect(page.getByTestId('step-title').last()).toHaveText('Who are you?');
  const handle = `e2e${Date.now()}`.toLowerCase();
  await page.getByTestId('identity-name').fill('E2E User');
  await page.getByTestId('identity-handle').fill(handle);
  await page.getByTestId('identity-next').click();

  // Step 3: Roles
  await expect(page.getByTestId('step-title').last()).toHaveText('What do you do?');
  await page.getByTestId('role-builder').click();
  await page.getByTestId('roles-next').click();

  // Step 4: About
  await expect(page.getByTestId('step-title').last()).toHaveText('A bit about you');
  await page.getByTestId('about-city').fill('San Francisco');
  await page.getByTestId('about-country').fill('USA');
  await page.getByTestId('about-finish').click();

  // Land on home with the correct identity
  await expect(page.getByTestId('home-title')).toBeVisible({ timeout: 15_000 });
  await expect(page.getByTestId('home-avatar')).toBeVisible();
});
