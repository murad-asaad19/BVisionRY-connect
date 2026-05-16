describe('env', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...originalEnv };
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  it('reads valid Supabase URL and anon key', () => {
    process.env.EXPO_PUBLIC_SUPABASE_URL = 'http://127.0.0.1:54321';
    process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY = 'sb_publishable_test';
    const { env } = require('~/lib/env');
    expect(env.SUPABASE_URL).toBe('http://127.0.0.1:54321');
    expect(env.SUPABASE_ANON_KEY).toBe('sb_publishable_test');
    expect(env.SENTRY_DSN).toBeUndefined();
    expect(env.FIREBASE_ENABLED).toBe(false);
  });

  it('throws if SUPABASE_URL is missing', () => {
    delete process.env.EXPO_PUBLIC_SUPABASE_URL;
    process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY = 'sb_publishable_test';
    expect(() => require('~/lib/env')).toThrow(/SUPABASE_URL/);
  });

  it('throws if SUPABASE_URL is not a URL', () => {
    process.env.EXPO_PUBLIC_SUPABASE_URL = 'not-a-url';
    process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY = 'sb_publishable_test';
    expect(() => require('~/lib/env')).toThrow();
  });

  it('parses FIREBASE_ENABLED as boolean', () => {
    process.env.EXPO_PUBLIC_SUPABASE_URL = 'http://127.0.0.1:54321';
    process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY = 'sb_publishable_test';
    process.env.EXPO_PUBLIC_FIREBASE_ENABLED = 'true';
    const { env } = require('~/lib/env');
    expect(env.FIREBASE_ENABLED).toBe(true);
  });
});
