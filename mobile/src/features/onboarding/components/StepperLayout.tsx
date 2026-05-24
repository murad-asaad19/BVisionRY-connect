import { ReactNode } from 'react';
import { View, Text, Pressable } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { ProgressDots } from '~/components/ui/ProgressDots';

type Props = {
  /** Current step (0-indexed). */
  currentIndex: number;
  /** Total number of steps. Defaults to 4 for the standard onboarding flow. */
  totalSteps?: number;
  title: string;
  /**
   * Override back-button visibility. Defaults to `currentIndex > 0` so the first
   * step never shows a back chevron.
   */
  canGoBack?: boolean;
  children: ReactNode;
};

export function StepperLayout({
  currentIndex,
  totalSteps = 4,
  title,
  canGoBack,
  children,
}: Props) {
  const { t } = useTranslation();
  const showBack = canGoBack ?? currentIndex > 0;
  return (
    <View className="flex-1 bg-surface px-6 pt-16">
      <ProgressDots
        steps={totalSteps}
        currentIndex={currentIndex}
        testID="onboarding-progress"
      />

      {showBack && (
        <Pressable testID="step-back" onPress={() => router.back()} className="mb-4 self-start">
          <Text className="text-muted">‹ {t('onboarding.back')}</Text>
        </Pressable>
      )}

      <Text className="text-body text-2xl font-display-bold mb-6" testID="step-title">
        {title}
      </Text>

      <View className="flex-1">{children}</View>
    </View>
  );
}
