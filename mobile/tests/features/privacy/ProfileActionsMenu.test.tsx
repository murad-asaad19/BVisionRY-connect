import { render, fireEvent } from '@testing-library/react-native';
import { ProfileActionsMenu } from '~/features/privacy/components/ProfileActionsMenu';

jest.mock('expo-router', () => ({ router: { back: jest.fn() } }));
jest.mock('~/features/privacy/hooks/useBlockUser', () => ({
  useBlockUser: () => ({ mutate: jest.fn() }),
}));
jest.mock('~/features/privacy/hooks/useReportTarget', () => ({
  useReportTarget: () => ({ mutate: jest.fn(), isPending: false }),
}));

describe('ProfileActionsMenu', () => {
  it('menu hidden by default, opens on trigger tap', () => {
    const { queryByTestId, getByTestId } = render(
      <ProfileActionsMenu targetUserId="u1" targetHandle="alice" />
    );
    expect(queryByTestId('profile-actions-menu')).toBeNull();
    fireEvent.press(getByTestId('profile-actions-trigger'));
    expect(getByTestId('profile-actions-menu')).toBeTruthy();
    expect(getByTestId('profile-actions-block')).toBeTruthy();
    expect(getByTestId('profile-actions-report')).toBeTruthy();
  });
});
