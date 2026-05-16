import { useState } from 'react';
import { View, Alert } from 'react-native';
import { useTranslation } from 'react-i18next';
import { signInWithProvider } from '~/features/auth/services/socialAuth.service';
import type { SocialProvider } from '~/features/auth/services/socialAuth.service';
import { Button } from '~/components/ui/Button';

export function SocialSignInButtons() {
  const { t } = useTranslation();
  const [pending, setPending] = useState<SocialProvider | null>(null);

  const onTap = async (provider: SocialProvider) => {
    setPending(provider);
    try {
      await signInWithProvider(provider);
    } catch (e) {
      Alert.alert('Sign-in failed', (e as Error).message);
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
