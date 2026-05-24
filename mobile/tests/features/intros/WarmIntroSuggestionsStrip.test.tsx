import { render, fireEvent } from '@testing-library/react-native';
import type { WarmIntroSuggestion } from '~/features/intros/services/warmIntros.service';

// Mock the suggestions hook so we can drive the strip directly.
const mockSuggestionsHook = jest.fn();
jest.mock('~/features/intros/hooks/useWarmIntroSuggestions', () => ({
  useWarmIntroSuggestions: (...args: unknown[]) => mockSuggestionsHook(...args),
}));

// Mock the compose sheet so we can assert mount/open without dragging
// in the supabase client, React Query, or any session context.
jest.mock('~/features/intros/components/WarmIntroComposeSheet', () => {
  const { View, Text } = require('react-native');
  return {
    WarmIntroComposeSheet: ({
      visible,
      context,
    }: {
      visible: boolean;
      context: { mutualName: string; targetName: string } | null;
    }) =>
      visible && context ? (
        <View testID="warm-intro-compose-sheet">
          <Text>{`compose:${context.mutualName}->${context.targetName}`}</Text>
        </View>
      ) : null,
  };
});

// Stub out i18n so the test asserts against the english copy keys.
jest.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string, params?: Record<string, string | number>) => {
      if (key === 'intros.warm.stripTitle') return 'People your network can introduce you to';
      if (key === 'intros.warm.via_one') return `Via ${params?.name}`;
      if (key === 'intros.warm.via_other') return `Via ${params?.name} +${params?.extra}`;
      if (key === 'intros.warm.askCta') return `Ask ${params?.firstName}`;
      if (key.startsWith('discovery.roles.')) return key;
      return key;
    },
  }),
}));

import { WarmIntroSuggestionsStrip } from '~/features/intros/components/WarmIntroSuggestionsStrip';

function setSuggestions(data: WarmIntroSuggestion[] | undefined) {
  mockSuggestionsHook.mockReturnValue({ data });
}

const baseSuggestion: WarmIntroSuggestion = {
  targetId: 't1',
  targetHandle: 'bob',
  targetName: 'Bob Smith',
  targetPhotoUrl: null,
  targetPrimaryRole: 'founder',
  targetGoalType: 'co_found',
  mutualCount: 1,
  topMutualId: 'm1',
  topMutualName: 'Alice Jones',
  topMutualHandle: 'alice',
};

describe('WarmIntroSuggestionsStrip', () => {
  beforeEach(() => {
    mockSuggestionsHook.mockReset();
  });

  it('renders nothing while the hook is loading (no data)', () => {
    setSuggestions(undefined);
    const { queryByTestId } = render(<WarmIntroSuggestionsStrip />);
    expect(queryByTestId('warm-intro-strip')).toBeNull();
  });

  it('renders nothing when there are no suggestions', () => {
    setSuggestions([]);
    const { queryByTestId } = render(<WarmIntroSuggestionsStrip />);
    expect(queryByTestId('warm-intro-strip')).toBeNull();
  });

  it('renders the strip + a card per suggestion when data is present', () => {
    setSuggestions([
      baseSuggestion,
      { ...baseSuggestion, targetId: 't2', targetHandle: 'carol', targetName: 'Carol' },
    ]);
    const { getByTestId } = render(<WarmIntroSuggestionsStrip />);
    expect(getByTestId('warm-intro-strip')).toBeTruthy();
    expect(getByTestId('warm-intro-card-bob')).toBeTruthy();
    expect(getByTestId('warm-intro-card-carol')).toBeTruthy();
  });

  it('shows the via_other line when mutual_count > 1', () => {
    setSuggestions([{ ...baseSuggestion, mutualCount: 3 }]);
    const { getByTestId } = render(<WarmIntroSuggestionsStrip />);
    expect(getByTestId('warm-intro-card-via-bob').props.children).toBe('Via Alice Jones +2');
  });

  it('tapping the ask CTA opens the compose sheet for that suggestion', () => {
    setSuggestions([baseSuggestion]);
    const { getByTestId, queryByTestId } = render(<WarmIntroSuggestionsStrip />);
    expect(queryByTestId('warm-intro-compose-sheet')).toBeNull();

    fireEvent.press(getByTestId('warm-intro-card-ask-bob'));

    expect(getByTestId('warm-intro-compose-sheet')).toBeTruthy();
  });
});
