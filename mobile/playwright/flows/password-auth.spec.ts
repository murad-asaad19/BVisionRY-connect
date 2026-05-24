import { test, expect } from '@playwright/test';

import { newUserFixture, TEST_PASSWORD } from '../fixtures/users';
import {
  createUserViaAdmin,
  deleteUserViaAdmin,
  getAdminClient,
  signInWithPasswordUI,
} from '../helpers/onboard';

/**
 * Wave-4 password-auth E2E coverage. Covers the new email + password flow on
 * both /sign-in and /sign-up plus the @handle sign-in path that routes
 * through the `auth-handle-login` edge function.
 *
 * Tests favour admin-created users (`createUserViaAdmin`) over Mailpit because
 * password sign-up doesn't need email verification and admin users land
 * already-confirmed in `auth.users`. Each test that creates a user records the
 * id in `createdUserIds` so `afterAll` can tear them down.
 */

// Tests run serially per playwright.config.ts; this declaration is a guard
// against accidental parallelization within the file.
test.describe.configure({ mode: 'serial' });

const createdUserIds: string[] = [];

test.describe('Password auth — sign-up + sign-in', () => {
  test.afterAll(async () => {
    for (const id of createdUserIds) {
      await deleteUserViaAdmin(id);
    }
  });

  // -------------------------------------------------------------------------
  // SIGN-UP path
  // -------------------------------------------------------------------------

  test('1. sign-up happy path: email + password redirects to onboarding goal', async ({
    browser,
  }) => {
    // Fresh context so any prior test's localStorage / auth state can't bleed
    // into the SDK's GoTrueClient bootstrap.
    const ctx = await browser.newContext();
    const page = await ctx.newPage();

    const user = newUserFixture({ slug: 'signup-happy' });
    await page.goto('/sign-up');
    await page.getByTestId('sign-up-email').fill(user.email);
    await page.getByTestId('sign-up-password').fill(user.password);
    await page.getByTestId('sign-up-submit').click();

    // signUp installs a session immediately (no email verification needed for
    // the local Supabase stack). The auth gate then routes the new user
    // (profile.onboarded=false) to /(onboarding)/goal.
    await expect(page.getByTestId('step-title').last()).toHaveText("What's your goal?", {
      timeout: 15_000,
    });

    // Capture the user-id so afterAll can clean up. `profiles.email` was
    // dropped (PII minimization); look the new user up via the admin listUsers
    // API instead. The local stack ships a handful of seeded users so paging
    // isn't a concern here.
    const admin = getAdminClient();
    const { data: users } = await admin.auth.admin.listUsers();
    const u = users.users.find((u) => u.email === user.email);
    if (u) createdUserIds.push(u.id);

    await ctx.close();
  });

  test('2. sign-up rejects a <8 char password inline', async ({ page }) => {
    const user = newUserFixture({ slug: 'signup-short' });
    await page.goto('/sign-up');
    await page.getByTestId('sign-up-email').fill(user.email);
    // 7 chars exactly — one short of the minimum.
    await page.getByTestId('sign-up-password').fill('short77');
    await page.getByTestId('sign-up-submit').click();

    await expect(page.getByTestId('sign-up-password-error')).toBeVisible({ timeout: 5_000 });
    await expect(page.getByTestId('sign-up-password-error')).toHaveText(
      'Password must be at least 8 characters.'
    );

    // We must still be on /sign-up — no session was created.
    await expect(page).toHaveURL(/\/sign-up$/);
    // Title is rendered by the form so its presence proves we did not navigate.
    await expect(page.getByTestId('sign-up-title')).toBeVisible();
  });

  test('3. sign-up with a duplicate email surfaces sign-up-error', async ({ browser }) => {
    const ctx = await browser.newContext();
    const page = await ctx.newPage();

    // Pre-create the user via the admin API so the email already exists in
    // auth.users by the time the UI submits.
    const fixture = newUserFixture({ slug: 'signup-dup' });
    const seeded = await createUserViaAdmin({
      email: fixture.email,
      password: fixture.password,
    });
    createdUserIds.push(seeded.userId);

    await page.goto('/sign-up');
    await page.getByTestId('sign-up-email').fill(fixture.email);
    await page.getByTestId('sign-up-password').fill(fixture.password);
    await page.getByTestId('sign-up-submit').click();

    // Supabase has two behaviours for duplicate-email signups depending on the
    // `Email Enumeration Prevention` setting:
    //   - DISABLED (our local stack today): returns "User already registered"
    //     (422) → `mapAuthError` → `auth.errors.signUpFailed` → the localized
    //     "Sign-up failed" banner renders inside `sign-up-error`.
    //   - ENABLED (some hosted envs): returns an obfuscated success (no error,
    //     fake-empty session) → no banner, but no real session either, so the
    //     auth gate keeps the user on /sign-up.
    // We accept either: the banner appears with a mapped i18n string, OR the
    // page stays on /sign-up without progressing past the form.
    const banner = page.getByTestId('sign-up-error');
    const stayedOnSignUp = await Promise.race([
      banner.waitFor({ state: 'visible', timeout: 10_000 }).then(() => 'banner' as const),
      page
        .waitForURL(/\/(onboarding\/goal|home)/, { timeout: 10_000 })
        .then(() => 'navigated' as const)
        .catch(() => 'stayed' as const),
    ]);
    // We must NOT have navigated to onboarding/home — that would mean a real
    // session was issued to the duplicate-email signup (a security smell).
    expect(stayedOnSignUp).not.toBe('navigated');
    await expect(page).toHaveURL(/\/sign-up$/);
    if (stayedOnSignUp === 'banner') {
      await expect(banner).toHaveText(
        /(Too many attempts|Sign-up failed|Incorrect username|Something went wrong)/i
      );
    }

    await ctx.close();
  });

  test('4. sign-up with empty fields surfaces both required errors', async ({ page }) => {
    await page.goto('/sign-up');
    // No fills — submit a blank form.
    await page.getByTestId('sign-up-submit').click();

    await expect(page.getByTestId('sign-up-email-error')).toBeVisible({ timeout: 5_000 });
    await expect(page.getByTestId('sign-up-password-error')).toBeVisible({ timeout: 5_000 });
    // Should match the localized strings from en.json — emailRequired /
    // passwordRequired. (Form may also use the invalidEmail validator when
    // value is empty; accept either.)
    await expect(page.getByTestId('sign-up-email-error')).toHaveText(/Enter (your|a valid) email/i);
    await expect(page.getByTestId('sign-up-password-error')).toHaveText(
      /Enter your password|Password must be at least 8 characters/i
    );
  });

  // -------------------------------------------------------------------------
  // SIGN-IN path
  // -------------------------------------------------------------------------

  test('5. sign-in by email + password navigates away from /sign-in', async ({ browser }) => {
    const ctx = await browser.newContext();
    const page = await ctx.newPage();

    const fixture = newUserFixture({ slug: 'signin-email' });
    const seeded = await createUserViaAdmin({
      email: fixture.email,
      password: fixture.password,
    });
    createdUserIds.push(seeded.userId);

    await page.goto('/sign-in');
    await signInWithPasswordUI(page, {
      identifier: fixture.email,
      password: fixture.password,
    });

    // The user is admin-created with no profile changes, so the auth gate
    // routes to /(onboarding)/goal. Either onboarding or home counts as a
    // successful sign-in. URL check is the most stable signal across both.
    await expect(page).not.toHaveURL(/\/sign-in/, { timeout: 15_000 });

    await ctx.close();
  });

  test('6. sign-in by @handle + password navigates away from /sign-in', async ({ browser }) => {
    const ctx = await browser.newContext();
    const page = await ctx.newPage();

    const fixture = newUserFixture({ slug: 'signinhandle' });
    const seeded = await createUserViaAdmin({
      email: fixture.email,
      password: fixture.password,
      handle: fixture.handle,
      onboarded: true,
      name: 'Handle Login Tester',
    });
    createdUserIds.push(seeded.userId);

    await page.goto('/sign-in');
    await signInWithPasswordUI(page, {
      identifier: `@${fixture.handle}`,
      password: fixture.password,
    });

    // Onboarded user — auth gate should land us on /(app)/(tabs)/home.
    await expect(page).not.toHaveURL(/\/sign-in/, { timeout: 15_000 });

    await ctx.close();
  });

  test('7. sign-in by unknown handle shows the invalid-credentials banner', async ({ page }) => {
    await page.goto('/sign-in');
    await signInWithPasswordUI(page, {
      identifier: '@nonexistenthandle-xyz-9999',
      password: TEST_PASSWORD,
    });

    const banner = page.getByTestId('sign-in-error');
    await expect(banner).toBeVisible({ timeout: 15_000 });
    // The security fix unified errors: handle-not-found surfaces the SAME
    // localized message as a wrong password — auth.errors.invalidCredentials.
    await expect(banner).toHaveText('Incorrect username, email, or password.');
    await expect(page).toHaveURL(/\/sign-in/);
  });

  test('8. sign-in with wrong password shows the invalid-credentials banner', async ({
    browser,
  }) => {
    const ctx = await browser.newContext();
    const page = await ctx.newPage();

    const fixture = newUserFixture({ slug: 'signin-wrong' });
    const seeded = await createUserViaAdmin({
      email: fixture.email,
      password: fixture.password,
    });
    createdUserIds.push(seeded.userId);

    await page.goto('/sign-in');
    await signInWithPasswordUI(page, {
      identifier: fixture.email,
      password: 'completely-wrong-password-9999',
    });

    const banner = page.getByTestId('sign-in-error');
    await expect(banner).toBeVisible({ timeout: 15_000 });
    await expect(banner).toHaveText('Incorrect username, email, or password.');
    await expect(page).toHaveURL(/\/sign-in/);

    await ctx.close();
  });

  test('9. sign-in with empty fields surfaces inline required errors', async ({ page }) => {
    await page.goto('/sign-in');
    await page.getByTestId('sign-in-submit').click();

    await expect(page.getByTestId('sign-in-email-error')).toBeVisible({ timeout: 5_000 });
    await expect(page.getByTestId('sign-in-password-error')).toBeVisible({ timeout: 5_000 });
    await expect(page.getByTestId('sign-in-email-error')).toHaveText(
      'Enter your email or username.'
    );
    await expect(page.getByTestId('sign-in-password-error')).toHaveText('Enter your password.');
  });

  // -------------------------------------------------------------------------
  // MAGIC-LINK regression — the secondary action still works.
  // -------------------------------------------------------------------------

  test('10. magic-link button still triggers the sent banner', async ({ browser }) => {
    // Fresh context so we don't carry a session across tests.
    const ctx = await browser.newContext();
    const page = await ctx.newPage();

    const fixture = newUserFixture({ slug: 'signin-magic' });
    await page.goto('/sign-in');
    await page.getByTestId('sign-in-email').fill(fixture.email);
    await page.getByTestId('sign-in-magic-link').click();
    await expect(page.getByTestId('sign-in-sent')).toBeVisible({ timeout: 10_000 });

    await ctx.close();
  });
});
