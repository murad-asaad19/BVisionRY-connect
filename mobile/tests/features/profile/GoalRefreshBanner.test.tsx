import { render } from '@testing-library/react-native';

jest.mock('@react-native-async-storage/async-storage', () =>
  require('@react-native-async-storage/async-storage/jest/async-storage-mock')
);

// Mock SessionContext so the banner doesn't pull in supabase/env (which has no
// values under jest). The banner reads `useAuthSession().session?.user.id` —
// returning `null` keeps the snooze-button path inactive while letting the
// age-based visibility logic remain under test.
jest.mock('~/features/auth/SessionContext', () => ({
  useAuthSession: () => ({ session: null, loading: false }),
}));

import { GoalRefreshBanner } from '~/features/profile/components/GoalRefreshBanner';

describe('GoalRefreshBanner', () => {
  it('renders when updated >30d ago', () => {
    const old = new Date(Date.now() - 35 * 24 * 60 * 60 * 1000).toISOString();
    const { getByTestId } = render(<GoalRefreshBanner goalUpdatedAt={old} />);
    expect(getByTestId('goal-refresh-banner')).toBeTruthy();
  });
  it('renders when null', () => {
    const { getByTestId } = render(<GoalRefreshBanner goalUpdatedAt={null} />);
    expect(getByTestId('goal-refresh-banner')).toBeTruthy();
  });
  it('hides when fresh', () => {
    const recent = new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString();
    const { queryByTestId } = render(<GoalRefreshBanner goalUpdatedAt={recent} />);
    expect(queryByTestId('goal-refresh-banner')).toBeNull();
  });
});
