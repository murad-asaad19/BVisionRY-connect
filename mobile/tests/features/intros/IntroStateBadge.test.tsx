jest.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => {
      const map: Record<string, string> = {
        'intros.badge.delivered': 'Pending',
        'intros.badge.accepted': 'Accepted',
        'intros.badge.declined': 'Declined',
        'intros.badge.expired': 'Expired',
        'intros.badge.connected': 'Connected',
        'intros.badge.awaitingResponse': 'Delivered, awaiting response',
      };
      return map[key] ?? key;
    },
  }),
}));

import { render } from '@testing-library/react-native';
import { IntroStateBadge } from '~/features/intros/components/IntroStateBadge';

describe('IntroStateBadge', () => {
  it('renders Pending label for delivered state', () => {
    const { getByText } = render(<IntroStateBadge state="delivered" />);
    expect(getByText('Pending')).toBeTruthy();
  });
  it('renders Accepted label', () => {
    const { getByText } = render(<IntroStateBadge state="accepted" />);
    expect(getByText('Accepted')).toBeTruthy();
  });
  it('renders Declined label to recipient', () => {
    const { getByText } = render(<IntroStateBadge state="declined" audience="recipient" />);
    expect(getByText('Declined')).toBeTruthy();
  });
  it('redacts Declined for sender per §12', () => {
    const { getByText, queryByText } = render(
      <IntroStateBadge state="declined" audience="sender" />
    );
    expect(getByText('Delivered, awaiting response')).toBeTruthy();
    expect(queryByText('Declined')).toBeNull();
  });
  it('renders Expired label', () => {
    const { getByText } = render(<IntroStateBadge state="expired" />);
    expect(getByText('Expired')).toBeTruthy();
  });
  it('renders Connected label', () => {
    const { getByText } = render(<IntroStateBadge state="connected" />);
    expect(getByText('Connected')).toBeTruthy();
  });
});
