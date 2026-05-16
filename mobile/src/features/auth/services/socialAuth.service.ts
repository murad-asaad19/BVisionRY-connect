import * as Linking from 'expo-linking';
import { supabase } from '~/lib/supabase/client';

export type SocialProvider = 'apple' | 'google';

export async function signInWithProvider(provider: SocialProvider): Promise<void> {
  const redirectTo = Linking.createURL('/auth/callback');
  const { error } = await supabase.auth.signInWithOAuth({
    provider,
    options: { redirectTo },
  });
  if (error) throw new Error(error.message);
}
