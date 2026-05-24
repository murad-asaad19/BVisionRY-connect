/**
 * Coverage for <MeetingPlaybookCard>. The component composes
 * `useMeetingPlaybook(meetingId)` which itself sits on top of two services
 * (getMeetingPlaybook, generateMeetingPlaybook). We mock the services so
 * the test exercises just the rendering decisions:
 *   * loading skeleton when no cached row is yet known
 *   * five sections render when a playbook is present
 *   * regenerate button is disabled when rate-limited
 */

jest.mock('~/features/meetings/services/playbook.service', () => ({
  getMeetingPlaybook: jest.fn(),
  generateMeetingPlaybook: jest.fn(),
}));

import { render, fireEvent, act, waitFor } from '@testing-library/react-native';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import type { ReactNode } from 'react';
import { MeetingPlaybookCard } from '~/features/meetings/components/MeetingPlaybookCard';
import {
  generateMeetingPlaybook,
  getMeetingPlaybook,
} from '~/features/meetings/services/playbook.service';

const PLAYBOOK = {
  summary: 'Bob is a designer who likes cycling.',
  sharedInterests: ['Cycling', 'Berlin'],
  conversationStarters: ['What got you into UX?'],
  doNotes: ['Mention the cycling angle'],
  dontNotes: ["Don't open with a pitch"],
  generatedAt: new Date(Date.now() - 5 * 60_000).toISOString(),
};

function freshWrapper() {
  const qc = new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  });
  return function Wrapper({ children }: { children: ReactNode }) {
    return <QueryClientProvider client={qc}>{children}</QueryClientProvider>;
  };
}

describe('<MeetingPlaybookCard>', () => {
  beforeEach(() => jest.clearAllMocks());

  it('renders the loading skeleton while initial RPC + generation are in flight', async () => {
    // RPC pending forever for this test.
    (getMeetingPlaybook as jest.Mock).mockReturnValueOnce(new Promise(() => {}));

    const { findByTestId } = render(
      <MeetingPlaybookCard meetingId="mp1" targetName="Bob" />,
      { wrapper: freshWrapper() }
    );
    expect(await findByTestId('meeting-playbook-card-loading')).toBeTruthy();
  });

  it('renders all five sections + generated_at when a playbook is present', async () => {
    (getMeetingPlaybook as jest.Mock).mockResolvedValueOnce(PLAYBOOK);

    const { findByTestId, getByTestId } = render(
      <MeetingPlaybookCard meetingId="mp1" targetName="Bob" />,
      { wrapper: freshWrapper() }
    );

    expect(await findByTestId('meeting-playbook-card')).toBeTruthy();
    expect(getByTestId('meeting-playbook-summary')).toBeTruthy();
    expect(getByTestId('meeting-playbook-shared-interests')).toBeTruthy();
    expect(getByTestId('meeting-playbook-conversation-starters')).toBeTruthy();
    expect(getByTestId('meeting-playbook-do')).toBeTruthy();
    expect(getByTestId('meeting-playbook-dont')).toBeTruthy();
    expect(getByTestId('meeting-playbook-generated-at')).toBeTruthy();
  });

  it('disables the regenerate button after a manual regeneration (rate-limit)', async () => {
    (getMeetingPlaybook as jest.Mock).mockResolvedValueOnce(PLAYBOOK);
    (generateMeetingPlaybook as jest.Mock).mockResolvedValueOnce({
      ...PLAYBOOK,
      generatedAt: new Date().toISOString(),
    });

    const { findByTestId } = render(
      <MeetingPlaybookCard meetingId="mp1" targetName="Bob" />,
      { wrapper: freshWrapper() }
    );

    const btn = await findByTestId('meeting-playbook-regenerate');
    expect(btn.props.accessibilityState?.disabled).toBeFalsy();

    await act(async () => {
      fireEvent.press(btn);
    });

    await waitFor(() => {
      expect(generateMeetingPlaybook).toHaveBeenCalledWith('mp1', true);
    });

    // After a successful manual regenerate, the cooldown kicks in.
    await waitFor(() => {
      const btn2 = findByTestId('meeting-playbook-regenerate');
      return btn2.then((node) => {
        expect(node.props.accessibilityState?.disabled).toBe(true);
      });
    });
  });

  it('renders the error banner when no cached row exists and generation fails', async () => {
    (getMeetingPlaybook as jest.Mock).mockResolvedValueOnce(null);
    (generateMeetingPlaybook as jest.Mock).mockRejectedValueOnce(
      new Error('generation_failed')
    );

    const { findByTestId } = render(
      <MeetingPlaybookCard meetingId="mp1" targetName="Bob" />,
      { wrapper: freshWrapper() }
    );

    expect(await findByTestId('meeting-playbook-card-error')).toBeTruthy();
  });
});
