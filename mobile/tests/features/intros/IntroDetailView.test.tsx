// Component test for the IntroDetailView warm_forward "Forwarded by …"
// caption introduced in 20260608060000_warm_intros_fixes.sql (finding #15).
//
// We mock the hooks that hit the network so the component renders
// synchronously: useIntroById returns the canned intro row, the supabase
// `from('profiles')` lookup used by useProfileLite is stubbed via a chained
// builder, and the auth session returns a stable user id.

jest.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string, vars?: Record<string, unknown>) => {
      const map: Record<string, string> = {
        'intros.detail.notFound': 'Not found',
        'intros.detail.back': 'Back',
        'intros.detail.from': 'FROM',
        'intros.detail.to': 'TO',
        'intros.detail.accepted': 'Accepted',
        'intros.detail.declined': 'Declined',
        'intros.detail.expiredHint': 'Expired',
        'intros.detail.declineSilent': 'Decline is silent',
        'intros.detail.decline': 'Decline',
        'intros.detail.accept': 'Accept',
        'intros.detail.acceptFailed': 'Accept failed',
        'intros.detail.declineFailed': 'Decline failed',
        'intros.compose.errorExpired': 'Expired',
        'intros.detail.says': 'NOTE FROM ' + ((vars?.name as string) ?? ''),
        'intros.detail.note': 'NOTE',
        'intros.warm.kindWarmRequestBadge': 'Warm intro request',
        'intros.warm.kindWarmForwardVia': 'Via ' + ((vars?.name as string) ?? ''),
        'intros.warm.viaForwarder': 'Forwarded by ' + ((vars?.name as string) ?? ''),
        'intros.warm.forwardTitle': 'Forward to ' + ((vars?.targetName as string) ?? ''),
      };
      return map[key] ?? key;
    },
  }),
}));

jest.mock('expo-router', () => ({
  router: { back: jest.fn(), push: jest.fn() },
  useRouter: () => ({ back: jest.fn(), push: jest.fn() }),
}));

jest.mock('~/features/intros/hooks/useIntroById');
jest.mock('~/features/intros/hooks/useAcceptIntro', () => ({
  useAcceptIntro: () => ({ mutateAsync: jest.fn(), isPending: false }),
}));
jest.mock('~/features/intros/hooks/useDeclineIntro', () => ({
  useDeclineIntro: () => ({ mutateAsync: jest.fn(), isPending: false }),
}));
jest.mock('~/features/auth/SessionContext', () => ({
  useAuthSession: () => ({
    session: { user: { id: 'carol-target-id' } },
  }),
}));

jest.mock('~/lib/supabase/client', () => {
  // Build a chainable mock that satisfies the .from(...).select(...).eq(...).single() call.
  const profiles: Record<string, { id: string; name: string; handle: string; photo_url: string | null }> = {
    'alice-asker-id':  { id: 'alice-asker-id',  name: 'Alice Asker', handle: 'alice', photo_url: null },
    'carol-target-id': { id: 'carol-target-id', name: 'Carol Target', handle: 'carol', photo_url: null },
    'bob-mutual-id':   { id: 'bob-mutual-id',   name: 'Bob Mutual',  handle: 'bob',   photo_url: null },
  };
  const makeBuilder = () => {
    let pendingId = '';
    const builder: any = {
      select: jest.fn(() => builder),
      eq: jest.fn((_col: string, value: string) => {
        pendingId = value;
        return builder;
      }),
      single: jest.fn(async () => ({ data: profiles[pendingId] ?? null, error: null })),
    };
    return builder;
  };
  return {
    supabase: {
      from: jest.fn(() => makeBuilder()),
    },
  };
});

import { waitFor } from '@testing-library/react-native';
import { renderWithProviders } from '../../helpers/renderWithProviders';
import { IntroDetailView } from '~/features/intros/components/IntroDetailView';
import { useIntroById } from '~/features/intros/hooks/useIntroById';

const FUTURE_ISO = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();

describe('IntroDetailView — warm_forward forwarder caption', () => {
  beforeEach(() => jest.clearAllMocks());

  it('renders "Forwarded by {forwarder}" banner for warm_forward intros', async () => {
    (useIntroById as jest.Mock).mockReturnValue({
      data: {
        id: 'intro-1',
        sender_id: 'alice-asker-id',
        recipient_id: 'carol-target-id',
        warm_target_id: 'bob-mutual-id', // back-ref to the forwarder
        note: 'A'.repeat(120),
        state: 'delivered',
        kind: 'warm_forward',
        expires_at: FUTURE_ISO,
      },
      isPending: false,
      isLoading: false,
      isError: false,
      error: null,
      status: 'success',
      isFetching: false,
      isSuccess: true,
    });

    const { findByTestId, findByText } = renderWithProviders(<IntroDetailView id="intro-1" />);

    // Prominent banner caption — name resolved via the supabase mock.
    expect(await findByTestId('intro-warm-forward-banner')).toBeTruthy();
    expect(await findByText('Forwarded by Bob Mutual')).toBeTruthy();
  });

  it('does NOT render the forwarder banner for direct intros', async () => {
    (useIntroById as jest.Mock).mockReturnValue({
      data: {
        id: 'intro-2',
        sender_id: 'alice-asker-id',
        recipient_id: 'carol-target-id',
        warm_target_id: null,
        note: 'A'.repeat(120),
        state: 'delivered',
        kind: 'direct',
        expires_at: FUTURE_ISO,
      },
      isPending: false,
      isLoading: false,
      isError: false,
      error: null,
      status: 'success',
      isFetching: false,
      isSuccess: true,
    });

    const { queryByTestId, findByText } = renderWithProviders(<IntroDetailView id="intro-2" />);
    // Wait for the body to render (counterpart name resolves) so we know the
    // tree has settled before asserting the negative.
    await findByText('Alice Asker');
    await waitFor(() => {
      expect(queryByTestId('intro-warm-forward-banner')).toBeNull();
    });
  });
});
