import { ReactNode } from 'react';
import { View, Text, Pressable } from 'react-native';
import { router } from 'expo-router';
import { ProgressDots } from '~/components/ui/ProgressDots';

type Props = {
  /** Current step (0-indexed) for the onboarding order: goal → identity → roles → about. */
  currentIndex: 0 | 1 | 2 | 3;
  title: string;
  canGoBack?: boolean;
  children: ReactNode;
};

export function StepperLayout({ currentIndex, title, canGoBack = true, children }: Props) {
  return (
    <View className="flex-1 bg-surface px-6 pt-16">
      <ProgressDots steps={4} currentIndex={currentIndex} testID="onboarding-progress" />

      {canGoBack && (
        <Pressable testID="step-back" onPress={() => router.back()} className="mb-4 self-start">
          <Text className="text-muted">← Back</Text>
        </Pressable>
      )}

      <Text className="text-body text-2xl font-display-bold mb-6" testID="step-title">
        {title}
      </Text>

      <View className="flex-1">{children}</View>
    </View>
  );
}
