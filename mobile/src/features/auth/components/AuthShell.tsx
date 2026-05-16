import { View, Text } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useTranslation } from 'react-i18next';
import type { ReactNode } from 'react';

type Props = {
  children: ReactNode;
  /** testID to attach to the navy hero wordmark — sign-in.spec asserts white. */
  brandTestID?: string;
};

/**
 * Shared navy hero + gold radial + B/Connect wordmark used by sign-in and
 * sign-up. The inner card is full-width on phone (mockup A2/A3) — no
 * `max-w-sm` constraint.
 */
export function AuthShell({ children, brandTestID = 'auth-brand' }: Props) {
  const { t } = useTranslation();
  return (
    <View className="flex-1 bg-navy">
      <LinearGradient
        colors={['rgba(255,193,7,0.25)', 'transparent']}
        start={{ x: 0.5, y: 0 }}
        end={{ x: 0.5, y: 1 }}
        style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 260 }}
      />
      <View className="flex-1 px-5 pt-12">
        <View className="items-center mb-7">
          <Text
            className="font-display-bold text-[28px] text-white tracking-wide"
            testID={brandTestID}
          >
            <Text className="text-gold">B</Text>VisionRY{' '}
            <Text className="text-gold-light font-display-medium">Connect</Text>
          </Text>
          <Text className="font-display-medium text-[11px] text-gold-light mt-1">
            {t('signIn.brandTagline')}
          </Text>
        </View>
        <View className="bg-white rounded-2xl p-5 w-full self-center">{children}</View>
      </View>
    </View>
  );
}
