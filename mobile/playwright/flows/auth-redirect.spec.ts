import { test, expect } from '@playwright/test';

import { newUserFixture } from '../fixtures/users';
import { createUserViaAdmin, deleteUserViaAdmin, signInWithPasswordUI } from '../helpers/onboard';

/**
 * Wave-4 AuthLayout redirect verification + FOUC guard.
 *
 * Once a user has a session, `(auth)/_layout.tsx` calls `useNextRoute()` and
 * bounces them to either `/(app)/(tabs)/home` (onboarded) or
 * `/(onboarding)/goal` (still onboarding). Visiting any auth route while
 * already signed in should therefore never linger on the sign-in form.
 *
 * The FOUC test (#14) verifies the sign-in *form itself* (no session) renders
 * within 1s on a cold visit — the auth-layout spinner must only show when
 * there's an existing session to resolve.
 */

test.describe.configure({ mode: 'serial' });

const createdUserIds: string[] = [];

test.describe('AuthLayout — redirect when already signed in', () => {
  test.afterAll(async () => {
    for (const id of createdUserIds) {
      await deleteUserViaAdmin(id);
    }
  });

  test('11. signed-in onboarded user is bounced off /sign-in to /(app)/(tabs)/home', async ({
    browser,
  }) => {
    const ctx = await browser.newContext();
    const page = await ctx.newPage();

    const fixture = newUserFixture({ slug: 'redironboard' });
    const seeded = await createUserViaAdmin({
      email: fixture.email,
      password: fixture.password,
      handle: fixture.handle,
      onboarded: true,
      name: 'Redirect Tester',
    });
    createdUserIds.push(seeded.userId);

    // Sign in via the UI so SessionContext is properly populated; setSession
    // is what we'd otherwise have to mimic by hand. After this the user has
    // a real Supabase session in localStorage.
    await page.goto('/sign-in');
    await signInWithPasswordUI(page, {
      identifier: fixture.email,
      password: fixture.password,
    });
    // Wait until we've actually navigated off /sign-in before re-visiting it.
    await expect(page).not.toHaveURL(/\/sign-in/, { timeout: 15_000 });

    // Now visit /sign-in again — AuthLayout must redirect us straight to
    // the home tab because the profile is onboarded.
    await page.goto('/sign-in');
    await expect(page).toHaveURL(/\/home/, { timeout: 10_000 });

    await ctx.close();
  });

  test('12. signed-in not-yet-onboarded user is bounced off /sign-up to /(onboarding)/goal', async ({
    browser,
  }) => {
    const ctx = await browser.newContext();
    const page = await ctx.newPage();

    const fixture = newUserFixture({ slug: 'rediroboard' });
    const seeded = await createUserViaAdmin({
      email: fixture.email,
      password: fixture.password,
      // No handle / no onboarded -> profile.onboarded stays false.
    });
    createdUserIds.push(seeded.userId);

    await page.goto('/sign-in');
    await signInWithPasswordUI(page, {
      identifier: fixture.email,
      password: fixture.password,
    });
    await expect(page).not.toHaveURL(/\/sign-in/, { timeout: 15_000 });

    // Re-visit /sign-up — gate should send us to the onboarding goal step.
    await page.goto('/sign-up');
    await expect(page.getByTestId('step-title').last()).toHaveText("What's your goal?", {
      timeout: 10_000,
    });

    await ctx.close();
  });

  test('13. signed-in user visiting /auth is redirected out of the callback', async ({
    browser,
  }) => {
    const ctx = await browser.newContext();
    const page = await ctx.newPage();

    const fixture = newUserFixture({ slug: 'redirauth' });
    const seeded = await createUserViaAdmin({
      email: fixture.email,
      password: fixture.password,
      handle: fixture.handle,
      onboarded: true,
      name: 'Redirect Auth Tester',
    });
    createdUserIds.push(seeded.userId);

    await page.goto('/sign-in');
    await signInWithPasswordUI(page, {
      identifier: fixture.email,
      password: fixture.password,
    });
    await expect(page).not.toHaveURL(/\/sign-in/, { timeout: 15_000 });

    // /auth is the deep-link callback. It bounces to `/` which then runs the
    // gate; an onboarded user lands on the home tab.
    await page.goto('/auth');
    await expect(page).not.toHaveURL(/\/auth$/, { timeout: 10_000 });
    await expect(page).toHaveURL(/\/home/, { timeout: 10_000 });

    await ctx.close();
  });

  test('14. cold /sign-in renders the sign-in form within 1s (no FOUC spinner)', async ({
    browser,
  }) => {
    // Fresh context — no prior session, no localStorage state.
    const ctx = await browser.newContext();
    const page = await ctx.newPage();

    await page.goto('/sign-in');
    // The form's hero / welcome elements must be visible within 1s. We assert
    // on `sign-in-welcome` (rendered by SignInForm itself) AND on `sign-in-
    // email` because both are inside the white card the form mounts only when
    // the auth layout is past its loading state.
    await expect(page.getByTestId('sign-in-welcome')).toBeVisible({ timeout: 1_000 });
    await expect(page.getByTestId('sign-in-email')).toBeVisible({ timeout: 1_000 });

    await ctx.close();
  });
});
