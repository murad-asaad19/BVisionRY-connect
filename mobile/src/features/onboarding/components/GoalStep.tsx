import { useEffect, useRef, useState } from 'react';
import { View, Text, ScrollView, Pressable } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { StepperLayout } from './StepperLayout';
import { useOnboardingDraft } from '~/features/onboarding/store/useOnboardingDraft';
import { GoalTextSchema } from '~/features/profile/schemas';
import { inferGoalType } from '~/features/onboarding/services/inferGoal.service';
import { Input } from '~/components/ui/Input';
import { Button } from '~/components/ui/Button';
import { Pill } from '~/components/ui/Pill';
import type { Database } from '~/lib/supabase/types.gen';

type GoalType = Database['public']['Enums']['goal_type'];

const EXAMPLES = ['Hiring a fractional designer', 'Raising pre-seed for a healthtech idea'];

const GOAL_TYPES: readonly GoalType[] = [
  'hire',
  'be_hired',
  'co_found',
  'invest',
  'take_investment',
  'advise',
  'find_advisor',
  'peer_connect',
];

// Below this length we don't bother calling the model — short fragments
// produce noisy guesses and waste tokens. Spec: 20 chars.
const INFER_MIN_CHARS = 20;
// Debounce window: long enough that mid-word keystrokes don't fire, short
// enough that the inference feels responsive after the user pauses.
const INFER_DEBOUNCE_MS = 800;

type InferenceState =
  | { kind: 'idle' }
  | { kind: 'inferring' }
  | { kind: 'success'; goalType: GoalType }
  | { kind: 'failed' };

export function GoalStep() {
  const { t } = useTranslation();
  const { draft, setField } = useOnboardingDraft();
  const [text, setText] = useState(draft.goal_text ?? '');
  const [goalType, setGoalType] = useState<GoalType | null>(draft.goal_type ?? null);
  // True the moment the user taps a radio — once set, suppresses the
  // "we picked X" caption and never lets a subsequent inference overwrite
  // their choice. Manual selection wins.
  const [manuallyPicked, setManuallyPicked] = useState<boolean>(
    draft.goal_type !== undefined
  );
  const [inference, setInference] = useState<InferenceState>({ kind: 'idle' });
  const [error, setError] = useState<string | null>(null);

  // Track the latest debounce timer + in-flight AbortController so a new
  // keystroke cancels both the pending call and any request already in
  // flight. Refs (not state) because we don't want a re-render on change.
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const abortRef = useRef<AbortController | null>(null);
  // Mirror manuallyPicked into a ref so the timeout closure reads the latest
  // value without us having to re-trigger the effect (which would fire a
  // wasteful re-inference every time the user taps a radio).
  const manuallyPickedRef = useRef(manuallyPicked);
  useEffect(() => {
    manuallyPickedRef.current = manuallyPicked;
  }, [manuallyPicked]);

  useEffect(() => {
    // Cancel anything pending — the input changed.
    if (debounceRef.current) {
      clearTimeout(debounceRef.current);
      debounceRef.current = null;
    }
    if (abortRef.current) {
      abortRef.current.abort();
      abortRef.current = null;
    }

    const trimmed = text.trim();
    if (trimmed.length < INFER_MIN_CHARS) {
      // Too short to bother. Reset to idle (drops any stale caption from a
      // previous longer draft) but never wipe the user's manual selection.
      setInference({ kind: 'idle' });
      return;
    }

    debounceRef.current = setTimeout(async () => {
      const controller = new AbortController();
      abortRef.current = controller;
      setInference({ kind: 'inferring' });
      const result = await inferGoalType(
        {
          text: trimmed,
          primaryRole: draft.primary_role ?? null,
          roles: draft.roles ?? [],
        },
        controller.signal
      );
      // If a newer call took over, the AbortController on `abortRef` will
      // have been swapped — bail without touching state.
      if (abortRef.current !== controller) return;
      abortRef.current = null;

      if (result.goalType) {
        setInference({ kind: 'success', goalType: result.goalType });
        // Only auto-select if the user hasn't manually overridden. Read
        // from the ref so the latest value wins even if the user tapped a
        // radio while the request was in flight.
        if (!manuallyPickedRef.current) {
          setGoalType(result.goalType);
        }
      } else {
        setInference({ kind: 'failed' });
      }
    }, INFER_DEBOUNCE_MS);

    return () => {
      if (debounceRef.current) {
        clearTimeout(debounceRef.current);
        debounceRef.current = null;
      }
    };
    // Only `text` re-triggers inference. primary_role / roles are read from
    // `draft` inside the timeout (latest values). manuallyPicked is read
    // through manuallyPickedRef. draft is stable from useOnboardingDraft.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [text]);

  // Tear down any pending work on unmount so an abort doesn't fire after
  // React strips the component.
  useEffect(() => {
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
      if (abortRef.current) abortRef.current.abort();
    };
  }, []);

  const onSelectGoalType = (g: GoalType) => {
    setGoalType(g);
    setManuallyPicked(true);
  };

  const onNext = () => {
    const parsed = GoalTextSchema.safeParse(text);
    if (!parsed.success) {
      setError(t('onboarding.goal.errorRange'));
      return;
    }
    // Fallback to peer_connect when inference produced nothing and the user
    // didn't pick manually. Matches the deleted keyword-heuristic contract:
    // Next must always produce a goal_type rather than dead-end the user.
    const finalGoalType: GoalType = goalType ?? 'peer_connect';
    setField('goal_type', finalGoalType);
    setField('goal_text', parsed.data);
    router.push('/(onboarding)/identity');
  };

  return (
    <StepperLayout currentIndex={0} canGoBack={false} title={t('onboarding.goal.title')}>
      <ScrollView>
        <Input
          testID="goal-text"
          label={t('onboarding.goal.label')}
          value={text}
          onChangeText={(v) => {
            setText(v);
            setError(null);
          }}
          placeholder={t('onboarding.goal.placeholder')}
          multiline
          numberOfLines={4}
          maxLength={280}
        />
        <Text className="font-body text-[10px] text-muted mb-1">{text.length} / 280</Text>
        <Text className="font-body text-[10px] text-muted leading-snug mb-2">
          Examples: {EXAMPLES.map((e) => `"${e}"`).join(', ')}
        </Text>

        {inference.kind === 'inferring' && (
          <View className="mb-2" testID="goal-inferring">
            <Pill variant="muted">{t('onboarding.goal.inferring')}</Pill>
          </View>
        )}

        {inference.kind === 'success' && !manuallyPicked && (
          <Text testID="goal-inferred" className="font-body text-[11px] text-muted mb-2">
            {t('onboarding.goal.inferred', {
              label: t(`discovery.goals.${inference.goalType}`),
            })}
          </Text>
        )}

        {inference.kind === 'failed' && (
          <Text testID="goal-infer-failed" className="font-body text-[11px] text-muted mb-2">
            {t('onboarding.goal.inferFailed')}
          </Text>
        )}

        <View className="mt-2 mb-3">
          <Text className="font-body text-[12px] text-muted mb-2">
            {t('onboarding.goal.typeLabel')}
          </Text>
          <View className="flex-row flex-wrap" style={{ gap: 8 }}>
            {GOAL_TYPES.map((g) => {
              const selected = goalType === g;
              return (
                <Pressable
                  key={g}
                  testID={`goal-type-${g}`}
                  onPress={() => onSelectGoalType(g)}
                  accessibilityRole="radio"
                  accessibilityState={{ selected }}
                  className={`rounded-full px-3 py-1.5 ${
                    selected ? 'bg-navy' : 'bg-gold-pale'
                  }`}
                >
                  <Text
                    className={`font-display-bold text-[12px] ${
                      selected ? 'text-white' : 'text-navy'
                    }`}
                  >
                    {t(`discovery.goals.${g}`)}
                  </Text>
                </Pressable>
              );
            })}
          </View>
        </View>

        {error && (
          <Text testID="goal-error" className="text-danger-text mt-2 mb-2">
            {error}
          </Text>
        )}

        <View className="mt-2">
          <Button testID="goal-next" variant="primary" onPress={onNext}>
            {t('onboarding.goal.next')}
          </Button>
        </View>
      </ScrollView>
    </StepperLayout>
  );
}
