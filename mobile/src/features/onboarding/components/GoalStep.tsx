import { useState } from 'react';
import { View, Text, ScrollView } from 'react-native';
import { router } from 'expo-router';
import { StepperLayout } from './StepperLayout';
import { useOnboardingDraft } from '~/features/onboarding/store/useOnboardingDraft';
import { GoalTextSchema } from '~/features/profile/schemas';
import { Input } from '~/components/ui/Input';
import { Button } from '~/components/ui/Button';
import type { Database } from '~/lib/supabase/types.gen';

type GoalType = Database['public']['Enums']['goal_type'];

const EXAMPLES = ['Hiring a fractional designer', 'Raising pre-seed for a healthtech idea'];

// We default the goal_type at submission time when the user only supplies the
// free-form text — AI (B3) is deferred, so we pick a generic catch-all for the
// initial value. The user can refine via profile edit later.
const DEFAULT_GOAL_TYPE: GoalType = 'peer_connect';

export function GoalStep() {
  const { draft, setField } = useOnboardingDraft();
  const [text, setText] = useState(draft.goal_text ?? '');
  const [error, setError] = useState<string | null>(null);

  const onNext = () => {
    const parsed = GoalTextSchema.safeParse(text);
    if (!parsed.success) {
      setError('Describe your goal in 10-280 characters.');
      return;
    }
    if (!draft.goal_type) {
      setField('goal_type', DEFAULT_GOAL_TYPE);
    }
    setField('goal_text', parsed.data);
    router.push('/(onboarding)/identity');
  };

  return (
    <StepperLayout currentIndex={0} canGoBack={false} title="What's your goal?">
      <ScrollView>
        <Input
          testID="goal-text"
          label="Goal"
          value={text}
          onChangeText={(t) => {
            setText(t);
            setError(null);
          }}
          placeholder="I'm looking to..."
          multiline
          numberOfLines={4}
          maxLength={280}
        />
        <Text className="font-body text-[10px] text-muted mb-1">{text.length} / 280</Text>
        <Text className="font-body text-[10px] text-muted leading-snug mb-4">
          Examples: {EXAMPLES.map((e) => `"${e}"`).join(', ')}
        </Text>

        {error && (
          <Text testID="goal-error" className="text-danger-text mt-2 mb-2">
            {error}
          </Text>
        )}

        <View className="mt-2">
          <Button testID="goal-next" variant="primary" onPress={onNext}>
            Next
          </Button>
        </View>
      </ScrollView>
    </StepperLayout>
  );
}
