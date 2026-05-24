import { z } from 'zod';

const Schema = z.object({
  SUPABASE_URL: z.string().url(),
  SUPABASE_ANON_KEY: z.string().min(1),
  SENTRY_DSN: z.string().optional(),
  SENTRY_ENV: z.string().default('dev'),
  // Accepts 'true' / 'TRUE' / '1' (case-insensitive). Anything else → false.
  FIREBASE_ENABLED: z
    .string()
    .optional()
    .default('false')
    .transform((v) => v?.toLowerCase() === 'true' || v === '1'),
  // EAS Update / project identity. Optional because local dev doesn't need it
  // (app.config.ts only injects it for cloud builds) and parse-time failure
  // here would block `expo start` for contributors without EAS access.
  EAS_PROJECT_ID: z.string().optional(),
  // Hostname for universal/app links (e.g. "connect.bvisionry.com"). Optional
  // for the same dev-friendliness reason as EAS_PROJECT_ID; deep-link
  // consumers should fall back gracefully when unset.
  APP_LINKS_HOST: z.string().optional(),
});

const parsed = Schema.safeParse({
  SUPABASE_URL: process.env.EXPO_PUBLIC_SUPABASE_URL,
  SUPABASE_ANON_KEY: process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY,
  SENTRY_DSN: process.env.EXPO_PUBLIC_SENTRY_DSN || undefined,
  SENTRY_ENV: process.env.EXPO_PUBLIC_SENTRY_ENV,
  FIREBASE_ENABLED: process.env.EXPO_PUBLIC_FIREBASE_ENABLED,
  EAS_PROJECT_ID: process.env.EXPO_PUBLIC_EAS_PROJECT_ID || undefined,
  APP_LINKS_HOST: process.env.EXPO_PUBLIC_APP_LINKS_HOST || undefined,
});

if (!parsed.success) {
  throw new Error(
    `Invalid environment configuration: ${JSON.stringify(parsed.error.flatten().fieldErrors)}`
  );
}

export const env = parsed.data;
