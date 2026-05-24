jest.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => {
      const map: Record<string, string> = {
        'opportunities.filter.remoteOnly': 'Remote only',
        'opportunities.filter.searchPlaceholder': 'Search opportunities…',
        'opportunities.kind.hiring': 'Hiring',
        'opportunities.kind.seeking_role': 'Seeking role',
        'opportunities.kind.fundraising': 'Fundraising',
        'opportunities.kind.investing': 'Investing',
        'opportunities.kind.cofounder': 'Cofounder',
        'opportunities.kind.advising': 'Advising',
        'opportunities.kind.seeking_advisor': 'Seeking advisor',
        'opportunities.kind.collaboration': 'Collaboration',
      };
      return map[key] ?? key;
    },
  }),
}));

import { render, fireEvent } from '@testing-library/react-native';
import {
  OpportunityFilterBar,
  type OpportunityFilters,
} from '~/features/opportunities/components/OpportunityFilterBar';

const EMPTY: OpportunityFilters = { kinds: [], remoteOnly: false, search: '' };

describe('OpportunityFilterBar', () => {
  it('emits onChange with the kind appended when an inactive kind chip is tapped', () => {
    const onChange = jest.fn();
    const { getByTestId } = render(<OpportunityFilterBar value={EMPTY} onChange={onChange} />);
    fireEvent.press(getByTestId('opportunity-filter-bar-kind-hiring'));
    expect(onChange).toHaveBeenCalledWith({ ...EMPTY, kinds: ['hiring'] });
  });

  it('emits onChange with the kind removed when an active chip is tapped', () => {
    const onChange = jest.fn();
    const { getByTestId } = render(
      <OpportunityFilterBar value={{ ...EMPTY, kinds: ['hiring'] }} onChange={onChange} />
    );
    fireEvent.press(getByTestId('opportunity-filter-bar-kind-hiring'));
    expect(onChange).toHaveBeenCalledWith({ ...EMPTY, kinds: [] });
  });

  it('emits onChange with remoteOnly toggled', () => {
    const onChange = jest.fn();
    const { getByTestId } = render(<OpportunityFilterBar value={EMPTY} onChange={onChange} />);
    fireEvent(getByTestId('opportunity-filter-bar-remote'), 'valueChange', true);
    expect(onChange).toHaveBeenCalledWith({ ...EMPTY, remoteOnly: true });
  });

  it('emits onChange when the search input changes', () => {
    const onChange = jest.fn();
    const { getByTestId } = render(<OpportunityFilterBar value={EMPTY} onChange={onChange} />);
    fireEvent.changeText(getByTestId('opportunity-filter-bar-search'), 'fintech');
    expect(onChange).toHaveBeenCalledWith({ ...EMPTY, search: 'fintech' });
  });
});
