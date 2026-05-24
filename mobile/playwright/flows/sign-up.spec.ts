import { test, expect } from '@playwright/test';
import { waitForMagicLink, purgeAllMessages } from '../helpers/mailpit';

test.describe('Sign-up route', () => {
  test('renders the create-account screen with all key surfaces', async ({ page }) => {
    await page.goto('/sign-up');
    await expect(page.getByTestId('sign-up-title')).toHaveText('Create your account');
    await expect(page.getByTestId('sign-up-email')).toBeVisible();
    await expect(page.getByTestId('sign-up-password')).toBeVisible();
    await expect(page.getByTestId('sign-up-submit')).toBeVisible();
    await expect(page.getByTestId('sign-up-magic-link')).toBeVisible();
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

  test('shows inline error for invalid email on the password path', async ({ page }) => {
    await page.goto('/sign-up');
    await page.getByTestId('sign-up-email').fill('not-an-email');
    await page.getByTestId('sign-up-password').fill('long-enough-pw');
    await page.getByTestId('sign-up-submit').click();
    // Input renders inline errors at `${testID}-error`.
    await expect(page.getByTestId('sign-up-email-error')).toContainText(/valid email/i, {
      timeout: 5_000,
    });
  });

  test('shows inline error when password is shorter than 8 characters', async ({ page }) => {
    await page.goto('/sign-up');
    await page.getByTestId('sign-up-email').fill(`good-${Date.now()}@example.com`);
    await page.getByTestId('sign-up-password').fill('short');
    await page.getByTestId('sign-up-submit').click();
    await expect(page.getByTestId('sign-up-password-error')).toContainText(/8 characters/i, {
      timeout: 5_000,
    });
  });

  test('password hint flips to success tone when length >= 8', async ({ page }) => {
    await page.goto('/sign-up');
    const hint = page.getByTestId('sign-up-password-hint');
    await expect(hint).toContainText(/8\+ characters/i);
    await page.getByTestId('sign-up-password').fill('longenough');
    await expect(hint).toContainText(/Looks good/i);
  });

  test('happy path: email -> magic link -> onboarding goal step', async ({ browser }) => {
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
    // The `sign-up-submit` button now requires a password too — use the
    // magic-link button for the passwordless happy path.
    await page.getByTestId('sign-up-magic-link').click();
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
