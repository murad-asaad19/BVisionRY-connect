import { test, expect } from '@playwright/test';
import { signUpAndOnboard } from '../helpers/onboard';
import { purgeAllMessages, waitForMagicLink } from '../helpers/mailpit';

test('two users send and receive live messages', async ({ browser }) => {
  test.setTimeout(120_000);
  await purgeAllMessages();
  const ts = Date.now();
  const aliceEmail = `alice-chat-${ts}@example.com`;
  const bobEmail = `bob-chat-${ts}@example.com`;
  const aliceHandle = `alicechat${ts}`.toLowerCase();
  const bobHandle = `bobchat${ts}`.toLowerCase();

  // 1. Alice signs up + onboards
  const aliceCtx = await browser.newContext();
  const alicePage = await aliceCtx.newPage();
  await signUpAndOnboard(alicePage, {
    email: aliceEmail,
    name: 'Alice Chat',
    handle: aliceHandle,
    role: 'builder',
    goalType: 'take_investment',
    goalText: 'Looking for investment for my early-stage AI startup.',
    city: 'San Francisco',
    country: 'USA',
  });
  await aliceCtx.close();

  await purgeAllMessages();

  // 2. Bob signs up + onboards
  const bobCtx = await browser.newContext();
  const bobPage = await bobCtx.newPage();
  await signUpAndOnboard(bobPage, {
    email: bobEmail,
    name: 'Bob Chat',
    handle: bobHandle,
    role: 'investor',
    goalType: 'invest',
    goalText: 'Looking to invest in early-stage AI startups.',
    city: 'San Francisco',
    country: 'USA',
  });

  // 3. Bob sends an intro to Alice
  await bobPage
    .getByTestId(`match-card-${aliceHandle}`)
    .waitFor({ state: 'visible', timeout: 15_000 });
  await bobPage.getByTestId(`match-card-${aliceHandle}`).click();
  await bobPage.getByTestId('other-profile-send-intro').click();
  const introNote =
    'Hi Alice, I noticed you are a builder working on AI products. Would love to chat about how my fund might help you scale.';
  await bobPage.getByTestId('compose-intro-note').fill(introNote);
  await bobPage.getByTestId('compose-intro-send').click();
  await expect(bobPage.getByTestId('intro-sent-banner')).toBeVisible({ timeout: 10_000 });

  await bobCtx.close();
  await purgeAllMessages();

  // 4. Alice signs back in and accepts the intro
  const alice2Ctx = await browser.newContext();
  const alice2Page = await alice2Ctx.newPage();
  await alice2Page.goto('/');
  await alice2Page.getByTestId('sign-in-email').fill(aliceEmail);
  await alice2Page.getByTestId('sign-in-submit').click();
  const aliceLink = await waitForMagicLink(aliceEmail);
  await alice2Page.goto(aliceLink);
  await alice2Page.getByTestId('home-avatar').waitFor({ state: 'visible', timeout: 15_000 });

  await alice2Page.getByText('Inbox', { exact: true }).first().click();
  await alice2Page
    .getByTestId('inbox-list-received')
    .waitFor({ state: 'visible', timeout: 10_000 });
  const introRow = alice2Page.getByTestId(/^intro-row-/).first();
  await introRow.click();
  await alice2Page.getByTestId('intro-accept').scrollIntoViewIfNeeded();
  await alice2Page.getByTestId('intro-accept').click();
  await expect(alice2Page.getByTestId('intro-state-badge-connected')).toBeVisible({
    timeout: 10_000,
  });

  // 5. Alice opens Chats tab and the conversation with Bob.
  // The intro detail screen is a stack route over (tabs), so the tab bar is
  // hidden — navigate directly to /chats instead of clicking the tab label.
  await alice2Page.goto('/chats');
  const aliceConvRow = alice2Page.getByTestId(`conversation-row-${bobHandle}`);
  await aliceConvRow.waitFor({ state: 'visible', timeout: 10_000 });
  await aliceConvRow.click();
  await expect(alice2Page.getByTestId('conversation-peer-name')).toHaveText('Bob Chat');

  // 6. Bob signs back in in parallel and opens the same conversation
  await purgeAllMessages();
  const bob2Ctx = await browser.newContext();
  const bob2Page = await bob2Ctx.newPage();
  await bob2Page.goto('/');
  await bob2Page.getByTestId('sign-in-email').fill(bobEmail);
  await bob2Page.getByTestId('sign-in-submit').click();
  const bobLink = await waitForMagicLink(bobEmail);
  await bob2Page.goto(bobLink);
  await bob2Page.getByTestId('home-avatar').waitFor({ state: 'visible', timeout: 15_000 });
  await bob2Page.goto('/chats');
  const bobConvRow = bob2Page.getByTestId(`conversation-row-${aliceHandle}`);
  await bobConvRow.waitFor({ state: 'visible', timeout: 10_000 });
  await bobConvRow.click();
  await expect(bob2Page.getByTestId('conversation-peer-name')).toHaveText('Alice Chat');

  // 7. THE REALTIME TEST — Alice sends, Bob sees via Realtime
  await alice2Page.getByTestId('composer-input').fill('Hi Bob! Got your intro.');
  await alice2Page.getByTestId('composer-send').click();
  await expect(bob2Page.locator('text="Hi Bob! Got your intro."')).toBeVisible({ timeout: 8_000 });

  // 8. Bob replies, Alice sees it
  await bob2Page.getByTestId('composer-input').fill('Hi Alice! Glad it landed.');
  await bob2Page.getByTestId('composer-send').click();
  await expect(alice2Page.locator('text="Hi Alice! Glad it landed."')).toBeVisible({
    timeout: 8_000,
  });

  // 9. Persistence: Bob reloads — both messages still there.
  // After reload, the chats list row's preview shows the latest message text,
  // which would collide with the message bubble in strict mode. Scope to the
  // message bubble testIDs to disambiguate.
  await bob2Page.reload();
  await bob2Page.goto('/chats');
  await bob2Page.getByTestId(`conversation-row-${aliceHandle}`).click();
  await expect(
    bob2Page.getByTestId('message-bubble-theirs').filter({ hasText: 'Hi Bob! Got your intro.' })
  ).toBeVisible({ timeout: 10_000 });
  await expect(
    bob2Page.getByTestId('message-bubble-mine').filter({ hasText: 'Hi Alice! Glad it landed.' })
  ).toBeVisible({ timeout: 5_000 });

  await alice2Ctx.close();
  await bob2Ctx.close();
});

test('two users propose and confirm a meeting', async ({ browser }) => {
  test.setTimeout(120_000);
  await purgeAllMessages();
  const ts = Date.now();
  const aliceEmail = `alice-mtg-${ts}@example.com`;
  const bobEmail = `bob-mtg-${ts}@example.com`;
  const aliceHandle = `alicemtg${ts}`.toLowerCase();
  const bobHandle = `bobmtg${ts}`.toLowerCase();

  const aliceCtx = await browser.newContext();
  const alicePage = await aliceCtx.newPage();
  await signUpAndOnboard(alicePage, {
    email: aliceEmail,
    name: 'Alice Mtg',
    handle: aliceHandle,
    role: 'builder',
    goalType: 'take_investment',
    goalText: 'Looking for investment for my early-stage AI startup.',
    city: 'San Francisco',
    country: 'USA',
  });
  await aliceCtx.close();
  await purgeAllMessages();

  const bobCtx = await browser.newContext();
  const bobPage = await bobCtx.newPage();
  await signUpAndOnboard(bobPage, {
    email: bobEmail,
    name: 'Bob Mtg',
    handle: bobHandle,
    role: 'investor',
    goalType: 'invest',
    goalText: 'Looking to invest in early-stage AI startups.',
    city: 'San Francisco',
    country: 'USA',
  });

  await bobPage
    .getByTestId(`match-card-${aliceHandle}`)
    .waitFor({ state: 'visible', timeout: 15_000 });
  await bobPage.getByTestId(`match-card-${aliceHandle}`).click();
  await bobPage.getByTestId('other-profile-send-intro').click();
  await bobPage
    .getByTestId('compose-intro-note')
    .fill(
      'Hi Alice — quick note about why a meeting would be valuable. Looking forward to chatting.'
    );
  await bobPage.getByTestId('compose-intro-send').click();
  await expect(bobPage.getByTestId('intro-sent-banner')).toBeVisible({ timeout: 10_000 });
  await bobCtx.close();
  await purgeAllMessages();

  // Alice accepts the intro
  const alice2Ctx = await browser.newContext();
  const alice2Page = await alice2Ctx.newPage();
  await alice2Page.goto('/');
  await alice2Page.getByTestId('sign-in-email').fill(aliceEmail);
  await alice2Page.getByTestId('sign-in-submit').click();
  const aliceLink = await waitForMagicLink(aliceEmail);
  await alice2Page.goto(aliceLink);
  await alice2Page.getByTestId('home-avatar').waitFor({ state: 'visible', timeout: 15_000 });
  await alice2Page.goto('/(app)/(tabs)/inbox');
  const introRow = alice2Page.getByTestId(/^intro-row-/).first();
  await introRow.click();
  await alice2Page.getByTestId('intro-accept').scrollIntoViewIfNeeded();
  await alice2Page.getByTestId('intro-accept').click();
  await expect(alice2Page.getByTestId('intro-state-badge-connected')).toBeVisible({
    timeout: 10_000,
  });

  // Alice opens the chat and proposes a meeting
  await alice2Page.goto('/(app)/(tabs)/chats');
  await alice2Page
    .getByTestId(`conversation-row-${bobHandle}`)
    .waitFor({ state: 'visible', timeout: 10_000 });
  await alice2Page.getByTestId(`conversation-row-${bobHandle}`).click();

  await alice2Page.getByTestId('composer-propose').click();
  const future = new Date(Date.now() + 7 * 86400_000);
  const pad = (n: number) => String(n).padStart(2, '0');
  const localValue = `${future.getFullYear()}-${pad(future.getMonth() + 1)}-${pad(future.getDate())}T${pad(future.getHours())}:${pad(future.getMinutes())}`;
  await alice2Page.getByTestId('propose-slot-1').fill(localValue);
  await alice2Page.getByTestId('propose-duration-30').click();
  await alice2Page.getByTestId('propose-submit').click();

  // Meeting card visible to Alice (proposer)
  await expect(alice2Page.getByTestId('meeting-card-proposed').first()).toBeVisible({
    timeout: 10_000,
  });

  // Bob signs back in, opens chat, confirms the meeting
  await purgeAllMessages();
  const bob2Ctx = await browser.newContext();
  const bob2Page = await bob2Ctx.newPage();
  await bob2Page.goto('/');
  await bob2Page.getByTestId('sign-in-email').fill(bobEmail);
  await bob2Page.getByTestId('sign-in-submit').click();
  const bobLink = await waitForMagicLink(bobEmail);
  await bob2Page.goto(bobLink);
  await bob2Page.getByTestId('home-avatar').waitFor({ state: 'visible', timeout: 15_000 });
  await bob2Page.goto('/(app)/(tabs)/chats');
  await bob2Page
    .getByTestId(`conversation-row-${aliceHandle}`)
    .waitFor({ state: 'visible', timeout: 10_000 });
  await bob2Page.getByTestId(`conversation-row-${aliceHandle}`).click();

  await expect(bob2Page.getByTestId('meeting-card-proposed').first()).toBeVisible({
    timeout: 10_000,
  });
  await bob2Page.getByTestId('meeting-slot-0').first().click();
  await bob2Page.getByTestId('meeting-confirm').first().click();

  // Confirmed card visible on both sides (Alice via realtime, Bob immediately)
  await expect(bob2Page.getByTestId('meeting-card-confirmed').first()).toBeVisible({
    timeout: 10_000,
  });
  await expect(alice2Page.getByTestId('meeting-card-confirmed').first()).toBeVisible({
    timeout: 10_000,
  });

  await alice2Ctx.close();
  await bob2Ctx.close();
});

test('server pipeline writes push_log on new message', async ({ browser }) => {
  test.setTimeout(120_000);
  await purgeAllMessages();
  const ts = Date.now();
  const aliceEmail = `alice-push-${ts}@example.com`;
  const bobEmail = `bob-push-${ts}@example.com`;
  const aliceHandle = `alicepush${ts}`.toLowerCase();
  const bobHandle = `bobpush${ts}`.toLowerCase();

  // 1. Both onboarded
  const aliceCtx = await browser.newContext();
  const alicePage = await aliceCtx.newPage();
  await signUpAndOnboard(alicePage, {
    email: aliceEmail,
    name: 'Alice Push',
    handle: aliceHandle,
    role: 'builder',
    goalType: 'take_investment',
    goalText: 'Looking for investment for my early-stage AI startup.',
    city: 'San Francisco',
    country: 'USA',
  });
  await aliceCtx.close();
  await purgeAllMessages();

  const bobCtx = await browser.newContext();
  const bobPage = await bobCtx.newPage();
  await signUpAndOnboard(bobPage, {
    email: bobEmail,
    name: 'Bob Push',
    handle: bobHandle,
    role: 'investor',
    goalType: 'invest',
    goalText: 'Looking to invest in early-stage AI startups.',
    city: 'San Francisco',
    country: 'USA',
  });

  // 2. Bob sends intro to Alice
  await bobPage
    .getByTestId(`match-card-${aliceHandle}`)
    .waitFor({ state: 'visible', timeout: 15_000 });
  await bobPage.getByTestId(`match-card-${aliceHandle}`).click();
  await bobPage.getByTestId('other-profile-send-intro').click();
  await bobPage
    .getByTestId('compose-intro-note')
    .fill(
      'Hi Alice, would love to connect about AI infra. A quick chat about your stack would be great.'
    );
  await bobPage.getByTestId('compose-intro-send').click();
  await expect(bobPage.getByTestId('intro-sent-banner')).toBeVisible({ timeout: 10_000 });
  await bobCtx.close();
  await purgeAllMessages();

  // 3. Alice accepts → conversation created
  const alice2Ctx = await browser.newContext();
  const alice2Page = await alice2Ctx.newPage();
  await alice2Page.goto('/');
  await alice2Page.getByTestId('sign-in-email').fill(aliceEmail);
  await alice2Page.getByTestId('sign-in-submit').click();
  const aliceLink = await waitForMagicLink(aliceEmail);
  await alice2Page.goto(aliceLink);
  await alice2Page.getByTestId('home-avatar').waitFor({ state: 'visible', timeout: 15_000 });
  await alice2Page.goto('/(app)/(tabs)/inbox');
  await alice2Page
    .getByTestId(/^intro-row-/)
    .first()
    .click();
  await alice2Page.getByTestId('intro-accept').scrollIntoViewIfNeeded();
  await alice2Page.getByTestId('intro-accept').click();
  await expect(alice2Page.getByTestId('intro-state-badge-connected')).toBeVisible({
    timeout: 10_000,
  });

  // 4. Alice sends a message in the new chat
  await alice2Page.goto('/(app)/(tabs)/chats');
  await alice2Page
    .getByTestId(`conversation-row-${bobHandle}`)
    .waitFor({ state: 'visible', timeout: 10_000 });
  await alice2Page.getByTestId(`conversation-row-${bobHandle}`).click();
  await alice2Page.getByTestId('composer-input').fill('Hi Bob, looking forward to chatting.');
  await alice2Page.getByTestId('composer-send').click();

  // 5. Wait for the trigger to fire + edge function to mark delivered
  // Use supabase-js inside the test to poll push_log.
  // The test runs in a Node context so we can hit supabase directly with
  // the same credentials the app uses.
  const { createClient } = await import('@supabase/supabase-js');
  const supabaseUrl = 'http://127.0.0.1:54321';
  const supabaseAnon = 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';
  const supabase = createClient(supabaseUrl, supabaseAnon, {
    auth: { persistSession: false },
  });

  // Sign in as Alice via password-grant equivalent — actually use a service role bypass:
  // Easier: query push_log without auth using a recipient_id filter via a direct DB shell.
  // But push_log has RLS for recipient_id=auth.uid(). For test, hit the DB directly via
  // npx supabase db query (Playwright runs in the host environment).
  // Use child_process to query push_log:
  const { execSync } = await import('node:child_process');
  let found = false;
  for (let i = 0; i < 30 && !found; i++) {
    const out = execSync(
      `npx supabase db query "select count(*)::int as n from public.push_log where event_table='messages';"`,
      { encoding: 'utf8' }
    );
    if (/\b[1-9]\d*\b/.test(out)) {
      found = true;
      break;
    }
    await new Promise((r) => setTimeout(r, 1000));
  }
  expect(found).toBe(true);

  await alice2Ctx.close();
});
