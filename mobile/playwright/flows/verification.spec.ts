import { test, expect } from '@playwright/test';
import { signUpAndOnboard } from '../helpers/onboard';
import { purgeAllMessages } from '../helpers/mailpit';
import { execSync } from 'node:child_process';

test.describe('Slice 7 — Verification', () => {
  test('settings shows connect button, badge appears after stub verification', async ({ page }) => {
    test.setTimeout(120_000);
    await purgeAllMessages();
    const ts = Date.now();
    const email = `verify-${ts}@example.com`;
    const handle = `verify${ts}`.toLowerCase();

    await signUpAndOnboard(page, {
      email,
      name: 'Verify User',
      handle,
      role: 'builder',
      goalType: 'peer_connect',
      goalText: 'Looking to connect with other AI builders worldwide.',
      city: 'Berlin',
      country: 'Germany',
    });

    // Open verification sub-screen (Phase 2 settings IA split)
    await page.goto('/(app)/settings/verification');
    await expect(page.getByTestId('settings-screen')).toBeVisible({ timeout: 10_000 });
    await expect(page.getByTestId('settings-github-connect')).toBeVisible();

    // Stub verification via direct DB write (E2E bypass)
    execSync(
      `npx supabase db query "update public.profiles set verified_github_username='octocat', verified_github_id=583231, verified_at=now() where handle='${handle}';"`,
      { encoding: 'utf8', cwd: '..' }
    );

    // Visit own profile page — badge should render
    await page.goto('/(app)/profile');
    await expect(page.getByTestId('verified-badge')).toBeVisible({ timeout: 10_000 });
    await expect(page.getByText('✓ @octocat')).toBeVisible();

    // Settings now shows connected state
    await page.goto('/(app)/settings/verification');
    await expect(page.getByTestId('settings-github-connected')).toBeVisible({ timeout: 10_000 });
    await expect(page.getByText('@octocat')).toBeVisible();
  });
});
