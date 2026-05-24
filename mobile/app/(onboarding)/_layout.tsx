import { Stack, Redirect, useSegments } from 'expo-router';
import { ActivityIndicator, View } from 'react-native';
import type { Href } from 'expo-router';
import { useCurrentUserProfile } from '~/features/profile/hooks/useCurrentUserProfile';
import { useOnboardingDraft } from '~/features/onboarding/store/useOnboardingDraft';

type OnboardingStep = 'goal' | 'identity' | 'roles' | 'about';

const STEP_ORDER: OnboardingStep[] = ['goal', 'identity', 'roles', 'about'];

/**
 * Pure resolver: given the current draft, return the earliest step the user
 * is allowed to reach. Onboarding fields are saved to `profiles` in one
 * atomic call from AboutStep, so DURING onboarding the source of truth for
 * "has the user completed step N?" is `useOnboardingDraft`, not the profile
 * (which stays empty until Finish). Strict order: goal_text → handle → roles
 * → bio. Bio is the OUTPUT of `about`, not a prerequisite, so reaching
 * `about` requires only that goal/handle/roles are populated.
 */
function earliestAllowedStep(draft: {
  goal_text?: string;
  handle?: string;
  roles?: string[];
}): OnboardingStep {
  if (!draft.goal_text) return 'goal';
  if (!draft.handle) return 'identity';
  if (!draft.roles || draft.roles.length === 0) return 'roles';
  return 'about';
}

export default function OnboardingLayout() {
  const profileQ = useCurrentUserProfile();
  const draft = useOnboardingDraft((s) => s.draft);
  const segments = useSegments();

  if (profileQ.isLoading) {
    return (
      <View className="flex-1 items-center justify-center bg-surface">
        <ActivityIndicator color="#fff" />
      </View>
    );
  }

  // segments looks like ['(onboarding)', '<step>'] — read the last segment
  // as the current step. If routing here without a step (e.g. /onboarding
  // root), defer to the resolver to pick the right entry point.
  const currentSegment = segments[segments.length - 1];
  const currentStep = STEP_ORDER.includes(currentSegment as OnboardingStep)
    ? (currentSegment as OnboardingStep)
    : null;

  const allowed = earliestAllowedStep(draft);
  const allowedIdx = STEP_ORDER.indexOf(allowed);
  const currentIdx = currentStep ? STEP_ORDER.indexOf(currentStep) : -1;

  if (currentStep === null || currentIdx > allowedIdx) {
    return <Redirect href={`/(onboarding)/${allowed}` as Href} />;
  }

  return (
    <Stack screenOptions={{ headerShown: false }} initialRouteName="goal">
      <Stack.Screen name="goal" />
      <Stack.Screen name="identity" />
      <Stack.Screen name="roles" />
      <Stack.Screen name="about" />
    </Stack>
  );
}
