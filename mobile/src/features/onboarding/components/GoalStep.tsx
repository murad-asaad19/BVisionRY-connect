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

// Heuristic inference of goal_type from the free-form goal text.
// Mockup B1 doesn't expose a goal_type picker — the spec says AI (B3) infers
// the kind. Until B3 ships, this keyword-rule pass keeps the matching
// algorithm useful (it relies on goal_type complementarity).
//
// Branch order matters: more-specific intents must precede related ones so
// that a sentence like "Looking to invest in startups raising pre-seed"
// resolves to `invest` (the speaker's role) rather than `take_investment`
// (the target's role). Same for `find_advisor` before `advise`.
//
// Spanish synonyms use `(?:^|\W)…(?:\W|$)` rather than `\b` because `\b` is
// defined as a transition between `\w` and `\W`, and accented chars / hyphens
// are `\W`, so `\bmentoría\b` and `\bco-fundador\b` would never match.
//
// TODO(B3-AI): replace keyword heuristic with AI classifier
export function inferGoalType(text: string): GoalType {
  const t = text.toLowerCase();

  // Investor intent (speaker invests) — must run before `take_investment`.
  if (
    /\b(investing|invest in|investor\b|portfolio\b|deal\s+flow)\b/.test(t) ||
    /(?:^|\W)(?:invertir|inversor|inversora|invirtiendo)(?:\W|$)/.test(t)
  )
    return 'invest';

  // Fundraiser intent (speaker raises).
  if (
    /\b(raising|raise|investment\b|funds?\b|pre[- ]?seed|series\s+[a-c]|seed\s+round)\b/.test(t) ||
    /(?:^|\W)(?:levantar\s+capital|recaudar\s+fondos|pre[- ]?semilla|pre[- ]?seed|ronda\s+semilla)(?:\W|$)/.test(
      t
    )
  )
    return 'take_investment';

  if (
    /\b(hiring|hire (?:a|an|some)|looking to hire)\b/.test(t) ||
    /(?:^|\W)(?:contratar|contratando|reclutar|reclutando)(?:\W|$)/.test(t)
  )
    return 'hire';

  if (
    /\b(looking for (?:work|a role|a job)|seeking (?:work|a role)|hire me|open to work)\b/.test(
      t
    ) ||
    /(?:^|\W)(?:buscar\s+trabajo|buscando\s+trabajo|busco\s+empleo|buscar\s+empleo|empleo)(?:\W|$)/.test(
      t
    )
  )
    return 'be_hired';

  if (
    /\b(co[- ]?founder?|co[- ]?found(?:ing)?)\b/.test(t) ||
    /(?:^|\W)(?:co[- ]?fundador|co[- ]?fundadora|cofundador|cofundadora)(?:\W|$)/.test(t)
  )
    return 'co_found';

  // Advisor-seeker intent — must run before `advise`.
  if (
    /\b(find|need|looking for) (?:an?\s+)?adviso?r/.test(t) ||
    /(?:^|\W)(?:buscar\s+mentor|buscar\s+asesor|busco\s+mentor|busco\s+asesor|necesito\s+mentor|necesito\s+asesor)(?:\W|$)/.test(
      t
    )
  )
    return 'find_advisor';

  // Advisor intent (speaker advises).
  if (
    /\b(advising|advisor|advise\b)\b/.test(t) ||
    /(?:^|\W)(?:asesorar|asesorando|asesor|mentor|mentoría|mentoria)(?:\W|$)/.test(t)
  )
    return 'advise';

  return 'peer_connect';
}

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
    setField('goal_type', draft.goal_type ?? inferGoalType(parsed.data));
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
