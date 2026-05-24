import { makeRedirectUri } from 'expo-auth-session';

/**
 * Single source of truth for the OAuth / magic-link redirect URI.
 *
 * Native: resolves to `connect-mobile://auth` (scheme must match app.config.ts).
 * Web: resolves to the current origin's `/auth` path.
 *
 * Both the magic-link (`signInWithOtp`) and OAuth (`signInWithOAuth`) flows
 * use this URI so the deep-link handler in `useSession` / `app/auth.tsx`
 * picks them up uniformly.
 */
export const authRedirectUri = makeRedirectUri({ scheme: 'connect-mobile', path: 'auth' });
