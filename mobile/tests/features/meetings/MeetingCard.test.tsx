jest.mock('~/lib/supabase/client', () => ({
  supabase: { rpc: jest.fn(), from: jest.fn() },
}));

import { render } from '@testing-library/react-native';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import type { ReactNode } from 'react';
import { MeetingCard } from '~/features/meetings/components/MeetingCard';

const baseProps = {
  conversationId: 'c1',
  myId: 'me',
  proposedById: 'them',
  meetingId: 'mp1',
  slots: ['2030-01-01T00:00:00Z', '2030-01-02T00:00:00Z'],
  confirmedSlot: null,
  durationMinutes: 30,
  meetingUrl: null,
  state: 'proposed' as const,
};

function wrapper({ children }: { children: ReactNode }) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return <QueryClientProvider client={qc}>{children}</QueryClientProvider>;
}

describe('MeetingCard', () => {
  it('shows slot list with confirm/decline for recipient on proposed state', () => {
    const { getByTestId, queryByTestId } = render(<MeetingCard {...baseProps} />, {
      wrapper,
    });
    expect(getByTestId('meeting-card-proposed')).toBeTruthy();
    expect(queryByTestId('meeting-slot-0')).toBeTruthy();
    expect(queryByTestId('meeting-slot-1')).toBeTruthy();
    expect(queryByTestId('meeting-confirm')).toBeTruthy();
    expect(queryByTestId('meeting-decline')).toBeTruthy();
  });

  it('hides confirm/decline buttons for the proposer', () => {
    const { queryByTestId } = render(<MeetingCard {...baseProps} myId="them" />, {
      wrapper,
    });
    expect(queryByTestId('meeting-confirm')).toBeNull();
    expect(queryByTestId('meeting-decline')).toBeNull();
  });

  it('shows confirmed slot on confirmed state with ICS download button', () => {
    const { getByTestId } = render(
      <MeetingCard {...baseProps} state="confirmed" confirmedSlot="2030-01-01T00:00:00Z" />,
      { wrapper }
    );
    expect(getByTestId('meeting-card-confirmed')).toBeTruthy();
    expect(getByTestId('meeting-ics-download')).toBeTruthy();
  });

  it('shows declined state', () => {
    const { getByTestId } = render(<MeetingCard {...baseProps} state="declined" />, {
      wrapper,
    });
    expect(getByTestId('meeting-card-declined')).toBeTruthy();
  });
});
