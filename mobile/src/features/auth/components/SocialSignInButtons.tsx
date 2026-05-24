import { useState } from 'react';
import { View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { signInWithProvider } from '~/features/auth/services/socialAuth.service';
import type { SocialProvider } from '~/features/auth/services/socialAuth.service';
import { Button } from '~/components/ui/Button';
import { useToast } from '~/components/ui/Toast';

/**
 * Map a raw Supabase / network error message onto a localized i18n key.
 * Keep heuristics narrow — we want predictable copy, not a regex zoo.
 */
function pickErrorKey(message: string): string {
  const m = message.toLowerCase();
  if (m.includes('cancel') || m.includes('dismiss')) return 'auth.errors.oauthCancelled';
  if (m.includes('network') || m.includes('fetch') || m.includes('timeout')) {
    return 'auth.errors.network';
  }
  return 'auth.errors.generic';
}

export function SocialSignInButtons() {
  const { t } = useTranslation();
  const toast = useToast();
  const [pending, setPending] = useState<SocialProvider | null>(null);

  const onTap = async (provider: SocialProvider) => {
    setPending(provider);
    try {
      const result = await signInWithProvider(provider);
      // User dismissed the OAuth sheet — silently bail out, no alert needed.
      if (result === 'cancelled') return;
    } catch (e) {
      const messageKey = pickErrorKey((e as Error).message ?? '');
      // P0-3: Branded toast instead of Alert.alert for OAuth failures.
      toast.error(`${t('auth.errors.socialSignInTitle')} · ${t(messageKey)}`);
    } finally {
      setPending(null);
    }
  };

  return (
    <View>
      <View className="mb-3">
        <Button
          testID="sign-in-google"
          variant="outline"
          onPress={() => onTap('google')}
          disabled={pending !== null}
          loading={pending === 'google'}
        >
          {t('signIn.google')}
        </Button>
      </View>
      <Button
        testID="sign-in-apple"
        variant="apple"
        onPress={() => onTap('apple')}
        disabled={pending !== null}
        loading={pending === 'apple'}
      >
        {t('signIn.apple')}
      </Button>
    </View>
  );
}
