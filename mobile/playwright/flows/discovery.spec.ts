import { test, expect } from '@playwright/test';
import { signUpAndOnboard } from '../helpers/onboard';
import { purgeAllMessages } from '../helpers/mailpit';

test('two users can discover each other', async ({ browser }) => {
  await purgeAllMessages();
  const ts = Date.now();
  const aliceHandle = `alice${ts}`.toLowerCase();
  const bobHandle = `bob${ts}`.toLowerCase();

  // Alice signs up + onboards in her own context
  const aliceCtx = await browser.newContext();
  const alicePage = await aliceCtx.newPage();
  await signUpAndOnboard(alicePage, {
    email: `alice-${ts}@example.com`,
    name: 'Alice Tester',
    handle: aliceHandle,
    role: 'builder',
    goalType: 'take_investment',
    goalText: 'Looking for investment for my early-stage AI startup.',
    city: 'San Francisco',
    country: 'USA',
  });
  await aliceCtx.close();

  // Bob signs up + onboards in his own context
  const bobCtx = await browser.newContext();
  const bobPage = await bobCtx.newPage();
  await signUpAndOnboard(bobPage, {
    email: `bob-${ts}@example.com`,
    name: 'Bob Tester',
    handle: bobHandle,
    role: 'investor',
    goalType: 'invest',
    goalText: 'Looking to invest in early-stage AI startups.',
    city: 'San Francisco',
    country: 'USA',
  });

  // Bob's home should show Alice in daily matches strip
  const aliceCard = bobPage.getByTestId(`match-card-${aliceHandle}`);
  await aliceCard.waitFor({ state: 'visible', timeout: 15_000 });

  // Tap Alice's match card → /p/[alice-handle]
  await aliceCard.click();
  await expect(bobPage.getByTestId('other-profile-name')).toHaveText('Alice Tester');
  await expect(bobPage.getByTestId('other-profile-handle')).toHaveText(`@${aliceHandle}`);

  await bobCtx.close();
});
