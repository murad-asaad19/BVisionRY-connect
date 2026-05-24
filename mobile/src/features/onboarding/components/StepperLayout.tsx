import { View, Text } from 'react-native';
import { useTranslation } from 'react-i18next';
import type { ReactNode } from 'react';
import { ProgressDots } from '~/components/ui/ProgressDots';
import { TopBar } from '~/components/ui/TopBar';

type Props = {
  /** Current step (0-indexed). */
  currentIndex: number;
  /** Total number of steps. Defaults to 4 for the standard onboarding flow. */
  totalSteps?: number;
  /**
   * Title rendered both inside the TopBar and as the large body heading.
   * Keeping a single source of truth avoids the title drifting between the
   * navigation chrome and the screen body.
   */
  title: string;
  /**
   * Localized short step name (e.g. "Goal", "Identity") rendered in the
   * "Step X of Y · {stepName}" caption above the progress bar.
   */
  stepName: string;
  /**
   * Override back-button visibility. Defaults to `currentIndex > 0` so the first
   * step never shows a back chevron.
   */
  canGoBack?: boolean;
  children: ReactNode;
};

/**
 * Onboarding step chrome — TopBar for navigation (P0-1, P2-2), Step X/Y caption
 * + progress bar (P2-14), then a large display-lg body title (P3-6) ahead of
 * the step content.
 */
export function StepperLayout({
  currentIndex,
  totalSteps = 4,
  title,
  stepName,
  canGoBack,
  children,
}: Props) {
  const { t } = useTranslation();
  const showBack = canGoBack ?? currentIndex > 0;
  return (
    <View className="flex-1 bg-surface">
      <TopBar back={showBack} title={title} size="md" titleTestID="step-topbar-title" />

      <View className="flex-1 px-gutter pt-4">
        <Text className="font-body text-body-xs text-muted mb-2 text-center">
          {t('onboarding.stepLabel', {
            current: currentIndex + 1,
            total: totalSteps,
            stepName,
          })}
        </Text>
        <ProgressDots
          steps={totalSteps}
          currentIndex={currentIndex}
          testID="onboarding-progress"
        />

        {/* P3-6: Migrate from text-2xl to text-display-lg from the typography scale. */}
        <Text
          className="font-display-bold text-display-lg text-body mb-6"
          testID="step-title"
        >
          {title}
        </Text>

        <View className="flex-1">{children}</View>
      </View>
    </View>
  );
}
