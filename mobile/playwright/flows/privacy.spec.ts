import { test, expect } from '@playwright/test';
import { signUpAndOnboard } from '../helpers/onboard';
import { purgeAllMessages } from '../helpers/mailpit';

test.describe('Slice 9 — Privacy', () => {
  test('block + unblock from profile, blocked list updates', async ({ browser }) => {
    test.setTimeout(180_000);
    await purgeAllMessages();
    const ts = Date.now();
    const aliceEmail = `alice-privacy-${ts}@example.com`;
    const bobEmail = `bob-privacy-${ts}@example.com`;
    const aliceHandle = `aliceprivacy${ts}`.toLowerCase();
    const bobHandle = `bobprivacy${ts}`.toLowerCase();

    const aliceCtx = await browser.newContext();
    const alicePage = await aliceCtx.newPage();
    await signUpAndOnboard(alicePage, {
      email: aliceEmail,
      name: 'Alice',
      handle: aliceHandle,
      role: 'builder',
      goalType: 'peer_connect',
      goalText: 'Looking to connect with other AI builders worldwide.',
      city: 'Berlin',
      country: 'Germany',
    });
    await aliceCtx.close();
    await purgeAllMessages();

    const bobCtx = await browser.newContext();
    const bobPage = await bobCtx.newPage();
    await signUpAndOnboard(bobPage, {
      email: bobEmail,
      name: 'Bob',
      handle: bobHandle,
      role: 'investor',
      goalType: 'invest',
      goalText: 'Looking to invest in early-stage AI startups worldwide.',
      city: 'San Francisco',
      country: 'USA',
    });

    // Visit Alice's profile by handle
    await bobPage.goto(`/p/${aliceHandle}`);
    await bobPage
      .getByTestId('profile-actions-trigger')
      .waitFor({ state: 'visible', timeout: 10_000 });
    await bobPage.getByTestId('profile-actions-trigger').click();
    await expect(bobPage.getByTestId('profile-actions-menu')).toBeVisible();

    await bobPage.getByTestId('profile-actions-block').click();

    // The block mutation fires asynchronously and immediately routes back.
    // Give the RPC time to settle before navigating to settings to avoid
    // racing the query that populates the blocked list.
    await bobPage.waitForTimeout(2000);

    // Bob navigates to settings → Blocked users sub-screen → list shows alice
    await bobPage.goto('/(app)/settings/blocked-users');
    await bobPage
      .getByTestId(`blocked-row-${aliceHandle}`)
      .waitFor({ state: 'visible', timeout: 15_000 });

    // Unblock
    await bobPage.getByTestId(`unblock-${aliceHandle}`).click();
    await expect(bobPage.getByTestId(`blocked-row-${aliceHandle}`)).toBeHidden({
      timeout: 10_000,
    });

    await bobCtx.close();
  });
});
