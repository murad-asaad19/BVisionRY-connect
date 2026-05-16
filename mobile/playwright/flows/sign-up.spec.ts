import { test, expect } from '@playwright/test';
import { waitForMagicLink, purgeAllMessages } from '../helpers/mailpit';

test.describe('Sign-up route', () => {
  test('renders the create-account screen with all key surfaces', async ({ page }) => {
    await page.goto('/sign-up');
    await expect(page.getByTestId('sign-up-title')).toHaveText('Create your account');
    await expect(page.getByTestId('sign-up-email')).toBeVisible();
    await expect(page.getByTestId('sign-up-submit')).toBeVisible();
    // SSO ladder (Google first, Apple second per gallery A2).
    await expect(page.getByTestId('sign-in-google')).toBeVisible();
    await expect(page.getByTestId('sign-in-apple')).toBeVisible();
    // Footer link.
    await expect(page.getByTestId('sign-up-go-sign-in')).toBeVisible();
  });

  test('"Have an account? Sign in" routes back to sign-in', async ({ page }) => {
    await page.goto('/sign-up');
    await page.getByTestId('sign-up-go-sign-in').click();
    await expect(page.getByTestId('sign-in-title')).toBeVisible({ timeout: 10_000 });
  });

  test('shows inline error for invalid email', async ({ page }) => {
    await page.goto('/sign-up');
    await page.getByTestId('sign-up-email').fill('not-an-email');
    await page.getByTestId('sign-up-submit').click();
    await expect(page.getByTestId('sign-up-error')).toContainText('valid email', {
      ignoreCase: true,
      timeout: 5_000,
    });
  });

  test('happy path: email → magic link → onboarding goal step', async ({ browser }) => {
    // Use a fresh context so we have a clean localStorage / cookie state.
    // Reusing the default page context across earlier `sign-in` tests
    // contaminates Supabase's GoTrueClient and the magic-link verifier
    // bounces straight back to /sign-in (verified manually via the MCP
    // Playwright browser).
    const ctx = await browser.newContext();
    const page = await ctx.newPage();

    const email = `e2e-signup-${Date.now()}@example.com`;
    await purgeAllMessages();

    await page.goto('/sign-up');
    await page.getByTestId('sign-up-email').fill(email);
    await page.getByTestId('sign-up-submit').click();
    await expect(page.getByTestId('sign-up-sent')).toBeVisible({ timeout: 10_000 });

    const magicLink = await waitForMagicLink(email);
    expect(magicLink).toMatch(/\/auth\/v1\/verify\?token=/);

    await page.goto(magicLink);

    // SessionContext consumes the URL fragment, sets the session, and
    // the (app)/_layout.tsx auth gate redirects new (non-onboarded) users
    // to /(onboarding)/goal.
    await expect(page.getByTestId('step-title').last()).toHaveText("What's your goal?", {
      timeout: 15_000,
    });

    await ctx.close();
  });
});
