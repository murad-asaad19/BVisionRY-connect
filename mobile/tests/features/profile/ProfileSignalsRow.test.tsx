import { render, fireEvent } from '@testing-library/react-native';
import type { ProfileSignals } from '~/features/profile/services/profileSignals.service';

// Mock the hook so the component is testable without a full React Query +
// SessionContext setup.
const mockHook = jest.fn();
jest.mock('~/features/profile/hooks/useProfileSignals', () => ({
  useProfileSignals: (...args: unknown[]) => mockHook(...args),
}));

// Mock the modal so we can assert it mounts without dragging the
// supabase client + react-query in.
jest.mock('~/features/profile/components/MutualConnectionsModal', () => {
  const { View, Text } = require('react-native');
  return {
    MutualConnectionsModal: ({ visible }: { visible: boolean }) =>
      visible ? (
        <View testID="mutual-connections-modal">
          <Text>modal</Text>
        </View>
      ) : null,
  };
});

import { ProfileSignalsRow } from '~/features/profile/components/ProfileSignalsRow';

function setSignals(data: ProfileSignals | null) {
  mockHook.mockReturnValue({ data });
}

describe('ProfileSignalsRow', () => {
  beforeEach(() => {
    mockHook.mockReset();
  });

  it('renders nothing when both signals are zero/null', () => {
    setSignals({
      mutualConnectionCount: 0,
      mutualTopUserIds: [],
      avgMeetingRating: null,
      totalMeetingReviews: 0,
    });
    const { queryByTestId } = render(<ProfileSignalsRow targetUserId="t1" />);
    expect(queryByTestId('profile-signals-row')).toBeNull();
  });

  it('renders nothing while loading (hook returns no data)', () => {
    setSignals(null);
    const { queryByTestId } = render(<ProfileSignalsRow targetUserId="t1" />);
    expect(queryByTestId('profile-signals-row')).toBeNull();
  });

  it('renders the mutual pill when count > 0', () => {
    setSignals({
      mutualConnectionCount: 3,
      mutualTopUserIds: ['u1', 'u2', 'u3'],
      avgMeetingRating: null,
      totalMeetingReviews: 0,
    });
    const { getByTestId, queryByTestId } = render(<ProfileSignalsRow targetUserId="t1" />);
    expect(getByTestId('profile-signals-row')).toBeTruthy();
    expect(getByTestId('profile-signals-mutual-pill')).toBeTruthy();
    expect(queryByTestId('profile-signals-rating-pill')).toBeNull();
  });

  it('renders the rating pill when total reviews >= 3 and avg is non-null', () => {
    setSignals({
      mutualConnectionCount: 0,
      mutualTopUserIds: [],
      avgMeetingRating: 4.3,
      totalMeetingReviews: 5,
    });
    const { getByTestId, queryByTestId } = render(<ProfileSignalsRow targetUserId="t1" />);
    expect(getByTestId('profile-signals-rating-pill')).toBeTruthy();
    expect(queryByTestId('profile-signals-mutual-pill')).toBeNull();
  });

  it('hides the rating pill when avg is null (under-threshold)', () => {
    setSignals({
      mutualConnectionCount: 0,
      mutualTopUserIds: [],
      avgMeetingRating: null,
      totalMeetingReviews: 2,
    });
    const { queryByTestId } = render(<ProfileSignalsRow targetUserId="t1" />);
    expect(queryByTestId('profile-signals-rating-pill')).toBeNull();
    expect(queryByTestId('profile-signals-row')).toBeNull();
  });

  it('renders both pills when both signals are present', () => {
    setSignals({
      mutualConnectionCount: 2,
      mutualTopUserIds: ['u1', 'u2'],
      avgMeetingRating: 4.7,
      totalMeetingReviews: 4,
    });
    const { getByTestId } = render(<ProfileSignalsRow targetUserId="t1" />);
    expect(getByTestId('profile-signals-mutual-pill')).toBeTruthy();
    expect(getByTestId('profile-signals-rating-pill')).toBeTruthy();
  });

  it('tapping the mutual pill opens the modal', () => {
    setSignals({
      mutualConnectionCount: 4,
      mutualTopUserIds: ['u1', 'u2', 'u3', 'u4'],
      avgMeetingRating: null,
      totalMeetingReviews: 0,
    });
    const { getByTestId, queryByTestId } = render(<ProfileSignalsRow targetUserId="t1" />);
    expect(queryByTestId('mutual-connections-modal')).toBeNull();
    fireEvent.press(getByTestId('profile-signals-mutual-pill'));
    expect(getByTestId('mutual-connections-modal')).toBeTruthy();
  });
});
