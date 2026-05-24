import { test, expect } from '@playwright/test';
import { signUpAndOnboard } from '../helpers/onboard';
import { purgeAllMessages, waitForMagicLink } from '../helpers/mailpit';

test('two users complete a send-and-accept intro flow', async ({ browser }) => {
  await purgeAllMessages();
  const ts = Date.now();
  const aliceHandle = `alice${ts}`.toLowerCase();
  const bobHandle = `bob${ts}`.toLowerCase();
  const aliceEmail = `alice-${ts}@example.com`;
  const bobEmail = `bob-${ts}@example.com`;

  // Alice signs up + onboards
  const aliceCtx = await browser.newContext();
  const alicePage = await aliceCtx.newPage();
  await signUpAndOnboard(alicePage, {
    email: aliceEmail,
    name: 'Alice Tester',
    handle: aliceHandle,
    role: 'builder',
    goalType: 'take_investment',
    goalText: 'Looking for investment for my early-stage AI startup.',
    city: 'San Francisco',
    country: 'USA',
  });
  await aliceCtx.close();

  // Bob signs up + onboards
  const bobCtx = await browser.newContext();
  const bobPage = await bobCtx.newPage();
  await signUpAndOnboard(bobPage, {
    email: bobEmail,
    name: 'Bob Tester',
    handle: bobHandle,
    role: 'investor',
    goalType: 'invest',
    goalText: 'Looking to invest in early-stage AI startups.',
    city: 'San Francisco',
    country: 'USA',
  });

  // Bob taps Alice's match card to navigate to her profile
  const aliceCard = bobPage.getByTestId(`match-card-${aliceHandle}`);
  await aliceCard.waitFor({ state: 'visible', timeout: 15_000 });
  await aliceCard.click();
  await expect(bobPage.getByTestId('other-profile-name')).toHaveText('Alice Tester');

  // Bob sends an intro
  await bobPage.getByTestId('other-profile-send-intro').click();
  const note =
    'Hi Alice, I noticed you are a builder working on AI products. Would love to chat about how my fund might help you scale.';
  expect(note.length).toBeGreaterThanOrEqual(80);
  expect(note.length).toBeLessThanOrEqual(400);
  await bobPage.getByTestId('compose-intro-note').fill(note);
  await bobPage.getByTestId('compose-intro-send').click();
  await expect(bobPage.getByTestId('intro-sent-banner')).toBeVisible({ timeout: 10_000 });

  await bobCtx.close();

  // Purge Alice's old magic link emails so waitForMagicLink picks up the
  // freshly-triggered one (not the stale sign-up link).
  await purgeAllMessages();

  // Alice signs in (new context) and checks her inbox
  const alice2Ctx = await browser.newContext();
  const alice2Page = await alice2Ctx.newPage();
  await alice2Page.goto('/');
  await alice2Page.getByTestId('sign-in-email').fill(aliceEmail);
  // Magic-link button (sign-in-submit is now the password flow).
  await alice2Page.getByTestId('sign-in-magic-link').click();
  const link = await waitForMagicLink(aliceEmail);
  await alice2Page.goto(link);

  // Should land on home (Alice is already onboarded)
  await alice2Page.getByTestId('home-avatar').waitFor({ state: 'visible', timeout: 15_000 });

  // Open Inbox tab — tab bar has 'Inbox' label
  await alice2Page.getByText('Inbox', { exact: true }).first().click();
  await expect(alice2Page.getByTestId('inbox-list-received')).toBeVisible({ timeout: 10_000 });

  // Open the intro from Bob
  const introRow = alice2Page.getByTestId(/^intro-row-/).first();
  await introRow.click();
  await expect(alice2Page.getByTestId('intro-note')).toContainText('Hi Alice');

  // Accept — scroll into view first in case the tab bar overlays the button
  const acceptBtn = alice2Page.getByTestId('intro-accept');
  await acceptBtn.scrollIntoViewIfNeeded();
  await acceptBtn.click();
  await expect(alice2Page.getByTestId('intro-state-badge-connected')).toBeVisible({
    timeout: 10_000,
  });

  await alice2Ctx.close();
});
