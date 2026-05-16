import { z } from 'zod';

const Schema = z.object({
  SUPABASE_URL: z.string().url(),
  SUPABASE_ANON_KEY: z.string().min(1),
  SENTRY_DSN: z.string().optional(),
  SENTRY_ENV: z.string().default('dev'),
  FIREBASE_ENABLED: z
    .string()
    .optional()
    .transform((v) => v === 'true'),
});

const parsed = Schema.safeParse({
  SUPABASE_URL: process.env.EXPO_PUBLIC_SUPABASE_URL,
  SUPABASE_ANON_KEY: process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY,
  SENTRY_DSN: process.env.EXPO_PUBLIC_SENTRY_DSN || undefined,
  SENTRY_ENV: process.env.EXPO_PUBLIC_SENTRY_ENV,
  FIREBASE_ENABLED: process.env.EXPO_PUBLIC_FIREBASE_ENABLED,
});

if (!parsed.success) {
  throw new Error(
    `Invalid environment configuration: ${JSON.stringify(parsed.error.flatten().fieldErrors)}`
  );
}

export const env = parsed.data;
