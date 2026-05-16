import { test, expect } from '@playwright/test';
import { waitForMagicLink, purgeAllMessages } from '../helpers/mailpit';

test('signed-in onboarded user edits profile', async ({ page }) => {
  const email = `edit-${Date.now()}@example.com`;
  await purgeAllMessages();

  // Sign in + onboard quickly
  await page.goto('/');
  await page.getByTestId('sign-in-email').fill(email);
  await page.getByTestId('sign-in-submit').click();
  const link = await waitForMagicLink(email);
  await page.goto(link);

  // Phase 2 onboarding order: Goal → Identity → Roles → About.
  await expect(page.getByTestId('step-title').last()).toHaveText("What's your goal?", {
    timeout: 15_000,
  });

  await page.getByTestId('goal-text').fill('Looking to invest in pre-seed AI startups.');
  await page.getByTestId('goal-next').click();

  await page.getByTestId('identity-name').fill('Original Name');
  await page.getByTestId('identity-handle').fill(`edit${Date.now()}`.toLowerCase());
  await page.getByTestId('identity-next').click();

  await page.getByTestId('role-investor').click();
  await page.getByTestId('roles-next').click();

  await page.getByTestId('about-city').fill('New York');
  await page.getByTestId('about-country').fill('USA');
  await page.getByTestId('about-finish').click();

  // Land on home, open profile
  await expect(page.getByTestId('home-avatar')).toBeVisible({ timeout: 15_000 });
  await page.getByTestId('home-avatar').click();

  await expect(page.getByTestId('profile-name')).toHaveText('Original Name');

  // Edit
  await page.getByTestId('profile-edit').click();
  await page.getByTestId('edit-name').fill('Edited Name');
  await page.getByTestId('edit-save').click();

  // Back on profile view with new name
  await expect(page.getByTestId('profile-name')).toHaveText('Edited Name');
});
