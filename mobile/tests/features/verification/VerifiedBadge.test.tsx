import { render } from '@testing-library/react-native';
import { VerifiedBadge } from '~/features/verification/components/VerifiedBadge';

describe('VerifiedBadge', () => {
  it('renders nothing when username is null', () => {
    const { queryByTestId } = render(<VerifiedBadge username={null} />);
    expect(queryByTestId('verified-badge')).toBeNull();
  });

  it('renders badge with @username when set', () => {
    const { getByTestId, getByText } = render(<VerifiedBadge username="octocat" />);
    expect(getByTestId('verified-badge')).toBeTruthy();
    expect(getByText('✓ @octocat')).toBeTruthy();
  });
});
