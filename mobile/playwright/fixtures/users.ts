/**
 * Shared factories for ad-hoc test-user data. Keeps email/handle/password
 * generation in one place so each spec stays focused on the assertion under
 * test rather than fixture bookkeeping.
 *
 * Email uniqueness is mandatory because tests run serially against a long-
 * lived local Supabase — colliding with a leftover user trips a "User already
 * registered" 422 from the admin API. We mint a timestamp + crypto-random
 * suffix per fixture.
 */
import { randomBytes } from 'node:crypto';

/** A password that satisfies the 8-char minimum the sign-up form enforces. */
export const TEST_PASSWORD = 'TestPass123!';

function randSuffix(): string {
  return `${Date.now()}-${randomBytes(3).toString('hex')}`;
}

export type NewUserOpts = {
  /** Prefix for the local-part — defaults to `pw-auth`. */
  slug?: string;
};

export type NewUser = {
  email: string;
  password: string;
  handle: string;
};

/**
 * Mint a fresh `(email, password, handle)` triple. Handles are kept short and
 * alphanumeric so they survive the `^[a-z0-9_]+$` constraint enforced by the
 * profiles handle CHECK constraint.
 */
export function newUserFixture(opts: NewUserOpts = {}): NewUser {
  const slug = (opts.slug ?? 'pwauth').toLowerCase().replace(/[^a-z0-9]/g, '');
  const suffix = randSuffix();
  return {
    email: `${slug}-${suffix}@example.com`,
    password: TEST_PASSWORD,
    handle: `${slug}${suffix.replace(/-/g, '')}`.slice(0, 24),
  };
}
