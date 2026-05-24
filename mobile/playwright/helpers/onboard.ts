import { execSync } from 'node:child_process';
import path from 'node:path';

import { Page, expect } from '@playwright/test';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

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
  // `sign-in-submit` is now the password-sign-in button. The Phase-3 magic-link
  // flow lives behind `sign-in-magic-link`, which still emits the email that
  // `waitForMagicLink` consumes.
  await page.getByTestId('sign-in-magic-link').click();
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

// ---------------------------------------------------------------------------
// Admin-side helpers (used by password-auth + auth-redirect specs)
// ---------------------------------------------------------------------------

const REPO_ROOT = path.resolve(__dirname, '..', '..', '..');

type SupabaseEnv = { url: string; serviceRoleKey: string; anonKey: string };
let supabaseEnvCache: SupabaseEnv | null = null;

/**
 * Reads the local Supabase project's URL + ANON + SERVICE_ROLE_KEY via the
 * `supabase status -o json` CLI. The CLI is the canonical source — it pulls
 * from the running docker stack so any rotation flows through automatically.
 * The result is cached for the lifetime of the test process (we never refresh).
 */
export function readSupabaseEnv(): SupabaseEnv {
  if (supabaseEnvCache) return supabaseEnvCache;
  const raw = execSync('npx supabase status -o json', {
    cwd: REPO_ROOT,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  // The CLI sometimes prepends a "Stopped services: [...]" line before the
  // JSON payload — slice from the first `{`.
  const jsonStart = raw.indexOf('{');
  const parsed = JSON.parse(raw.slice(jsonStart)) as Record<string, string>;
  const url = parsed.API_URL;
  const serviceRoleKey = parsed.SERVICE_ROLE_KEY;
  const anonKey = parsed.ANON_KEY;
  if (!url || !serviceRoleKey || !anonKey) {
    throw new Error('supabase status returned no API_URL / SERVICE_ROLE_KEY / ANON_KEY');
  }
  supabaseEnvCache = { url, serviceRoleKey, anonKey };
  return supabaseEnvCache;
}

let adminClientCache: SupabaseClient | null = null;

/**
 * Returns a memoized service-role client. The client persists no session and
 * never refreshes tokens — it's used purely for fixture seeding & teardown.
 */
export function getAdminClient(): SupabaseClient {
  if (adminClientCache) return adminClientCache;
  const { url, serviceRoleKey } = readSupabaseEnv();
  adminClientCache = createClient(url, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return adminClientCache;
}

type CreateUserOpts = {
  email: string;
  password: string;
  /** When set, also updates `profiles.handle` after the user is created. */
  handle?: string;
  /** When `true`, marks the profile as fully onboarded. */
  onboarded?: boolean;
  /** Optional display name (used when `onboarded` requires non-null fields). */
  name?: string;
};

export type CreatedUser = {
  userId: string;
  email: string;
  password: string;
};

/**
 * Creates an email-confirmed auth user via the admin API and optionally
 * promotes their profile row to a fully-onboarded state. Returns the user id
 * + the same credentials the caller passed in so tests can sign in via the
 * UI without round-tripping through Mailpit.
 *
 * The `handle_new_auth_user` DB trigger has already inserted a `profiles` row
 * by the time `admin.createUser` returns, so we UPDATE rather than INSERT to
 * avoid duplicate-key violations.
 */
export async function createUserViaAdmin(opts: CreateUserOpts): Promise<CreatedUser> {
  const admin = getAdminClient();
  const { data, error } = await admin.auth.admin.createUser({
    email: opts.email,
    password: opts.password,
    email_confirm: true,
  });
  if (error || !data?.user) {
    throw new Error(`createUserViaAdmin(${opts.email}): ${error?.message ?? 'no user'}`);
  }
  const userId = data.user.id;

  // Only touch profiles if the caller wants a handle or full onboarded state.
  const wantsProfileUpdate = opts.handle || opts.onboarded || opts.name;
  if (wantsProfileUpdate) {
    // Build a minimum-viable onboarded profile so the auth gate routes the
    // user to /(app)/(tabs)/home instead of /(onboarding)/goal.
    const patch: Record<string, unknown> = {};
    if (opts.handle) patch.handle = opts.handle;
    if (opts.name) patch.name = opts.name;
    if (opts.onboarded) {
      patch.name = patch.name ?? 'Password Auth User';
      patch.onboarded = true;
      patch.roles = ['builder'];
      patch.primary_role = 'builder';
      patch.goal_type = 'peer_connect';
      patch.goal_text =
        'Password-auth fixture user looking to peer-connect with other builders shipping product.';
      patch.city = 'Berlin';
      patch.country = 'Germany';
    }
    const { error: upErr } = await admin.from('profiles').update(patch).eq('id', userId);
    if (upErr) {
      throw new Error(`profile update for ${opts.email}: ${upErr.message}`);
    }
  }

  return { userId, email: opts.email, password: opts.password };
}

/**
 * Best-effort cleanup so a flaky run doesn't leave orphan auth users polluting
 * the next run. Swallows errors — callers use this in `afterAll`.
 */
export async function deleteUserViaAdmin(userId: string): Promise<void> {
  try {
    const admin = getAdminClient();
    await admin.auth.admin.deleteUser(userId);
  } catch {
    // best-effort
  }
}

// ---------------------------------------------------------------------------
// UI driver helpers
// ---------------------------------------------------------------------------

/**
 * Fills the sign-in form via testIDs and clicks `sign-in-submit` (password
 * path). Caller is responsible for asserting the post-submit state.
 *
 * `identifier` is whatever the form accepts: an email or an `@handle`.
 */
export async function signInWithPasswordUI(
  page: Page,
  opts: { identifier: string; password: string }
) {
  await page.getByTestId('sign-in-email').fill(opts.identifier);
  await page.getByTestId('sign-in-password').fill(opts.password);
  await page.getByTestId('sign-in-submit').click();
}

/**
 * Fills the email field on /sign-in and triggers the magic-link button.
 * Asserts the `sign-in-sent` banner so callers don't have to repeat that
 * boilerplate.
 */
export async function signInWithMagicLinkUI(page: Page, opts: { email: string }) {
  await page.getByTestId('sign-in-email').fill(opts.email);
  await page.getByTestId('sign-in-magic-link').click();
  await expect(page.getByTestId('sign-in-sent')).toBeVisible({ timeout: 10_000 });
}
