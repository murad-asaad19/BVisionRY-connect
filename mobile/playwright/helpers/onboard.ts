import { Page } from '@playwright/test';
import { waitForMagicLink } from './mailpit';

type OnboardOpts = {
  email: string;
  name: string;
  handle: string;
  role: 'founder' | 'leader' | 'builder' | 'investor';
  goalType:
    | 'hire'
    | 'be_hired'
    | 'co_found'
    | 'invest'
    | 'take_investment'
    | 'advise'
    | 'find_advisor'
    | 'peer_connect';
  goalText: string;
  city: string;
  country: string;
};

/**
 * Drives the Phase-2 onboarding flow in the new order:
 *   1. Goal (type + text)
 *   2. Identity (name + handle)
 *   3. Roles
 *   4. About (city + country)
 */
export async function signUpAndOnboard(page: Page, opts: OnboardOpts) {
  await page.goto('/');
  await page.getByTestId('sign-in-email').fill(opts.email);
  await page.getByTestId('sign-in-submit').click();
  const magicLink = await waitForMagicLink(opts.email);
  await page.goto(magicLink);

  await page.getByTestId('step-title').last().waitFor({ state: 'visible', timeout: 15_000 });

  // 1. Goal (free-form text — goal_type inferred / defaulted server-side)
  await page.getByTestId('goal-text').fill(opts.goalText);
  await page.getByTestId('goal-next').click();

  // 2. Identity
  await page.getByTestId('identity-name').fill(opts.name);
  await page.getByTestId('identity-handle').fill(opts.handle);
  await page.getByTestId('identity-next').click();

  // 3. Roles
  await page.getByTestId(`role-${opts.role}`).click();
  await page.getByTestId('roles-next').click();

  // 4. About
  await page.getByTestId('about-city').fill(opts.city);
  await page.getByTestId('about-country').fill(opts.country);
  await page.getByTestId('about-finish').click();

  await page.getByTestId('home-avatar').waitFor({ state: 'visible', timeout: 15_000 });
}
