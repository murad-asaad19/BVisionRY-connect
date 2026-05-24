jest.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string, params?: Record<string, string | number>) => {
      const map: Record<string, string> = {
        'opportunities.kind.hiring': 'Hiring',
        'opportunities.filter.remoteOnly': 'Remote only',
      };
      if (key === 'opportunities.detail.viewInterested')
        return `${params?.count ?? 0} interested`;
      return map[key] ?? key;
    },
  }),
}));

import { render, fireEvent } from '@testing-library/react-native';
import { OpportunityCard } from '~/features/opportunities/components/OpportunityCard';
import type { OpportunityFeedItem } from '~/features/opportunities/services/opportunities.service';

const baseOpportunity: OpportunityFeedItem = {
  id: 'o1',
  authorId: 'a1',
  kind: 'hiring',
  title: 'Hiring a senior PM',
  body: 'A long body explaining the role and what we are looking for.',
  tags: ['pm', 'fintech'],
  locationCity: 'Berlin',
  locationCountry: 'DE',
  remoteOk: true,
  expiresAt: null,
  createdAt: '2026-05-24T12:00:00Z',
  authorHandle: 'alice',
  authorName: 'Alice',
  authorPhotoUrl: null,
  authorPrimaryRole: 'founder',
  interestedCount: 3,
};

describe('OpportunityCard', () => {
  it('renders the title, body, kind chip, and tags', () => {
    const { getByTestId, getByText } = render(<OpportunityCard opportunity={baseOpportunity} />);
    expect(getByTestId('opportunity-card-o1-title').props.children).toBe('Hiring a senior PM');
    expect(getByTestId('opportunity-card-o1-body').props.children).toContain(
      'A long body explaining the role'
    );
    expect(getByText('Hiring')).toBeTruthy();
    expect(getByText('#pm')).toBeTruthy();
    expect(getByText('#fintech')).toBeTruthy();
  });

  it('shows remote pill when remote_ok is true', () => {
    const { getByTestId } = render(<OpportunityCard opportunity={baseOpportunity} />);
    expect(getByTestId('opportunity-card-o1-remote')).toBeTruthy();
  });

  it('shows the interested-count line when > 0', () => {
    const { getByTestId } = render(<OpportunityCard opportunity={baseOpportunity} />);
    expect(getByTestId('opportunity-card-o1-interested').props.children).toBe('3 interested');
  });

  it('omits interested-count when 0', () => {
    const { queryByTestId } = render(
      <OpportunityCard opportunity={{ ...baseOpportunity, interestedCount: 0 }} />
    );
    expect(queryByTestId('opportunity-card-o1-interested')).toBeNull();
  });

  it('fires onPress with the opportunity id when tapped', () => {
    const onPress = jest.fn();
    const { getByTestId } = render(
      <OpportunityCard opportunity={baseOpportunity} onPress={onPress} />
    );
    fireEvent.press(getByTestId('opportunity-card-o1'));
    expect(onPress).toHaveBeenCalledWith('o1');
  });
});
