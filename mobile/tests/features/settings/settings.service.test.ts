jest.mock('~/lib/supabase/client', () => ({
  supabase: {
    rpc: jest.fn(),
    functions: { invoke: jest.fn() },
  },
}));

jest.mock('~/features/auth/services/auth.service', () => ({
  signOut: jest.fn(),
}));

jest.mock('~/lib/query-client', () => ({
  queryClient: { clear: jest.fn() },
}));

jest.mock('~/features/discovery/store/feedFiltersStore', () => ({
  useFeedFiltersStore: { getState: jest.fn(() => ({ clear: jest.fn() })) },
}));
jest.mock('~/features/profile/store/profileNudgeStore', () => ({
  useProfileNudgeStore: { getState: jest.fn(() => ({ reset: jest.fn() })) },
}));
jest.mock('~/features/onboarding/store/useOnboardingDraft', () => ({
  useOnboardingDraft: { getState: jest.fn(() => ({ reset: jest.fn() })) },
}));
jest.mock('~/features/settings/store/telemetryStore', () => ({
  useTelemetryStore: { setState: jest.fn() },
}));

import { supabase } from '~/lib/supabase/client';
import { signOut } from '~/features/auth/services/auth.service';
import { queryClient } from '~/lib/query-client';
import { useFeedFiltersStore } from '~/features/discovery/store/feedFiltersStore';
import { useProfileNudgeStore } from '~/features/profile/store/profileNudgeStore';
import { useOnboardingDraft } from '~/features/onboarding/store/useOnboardingDraft';
import { useTelemetryStore } from '~/features/settings/store/telemetryStore';
import { exportMyData, deleteMyAccount } from '~/features/settings/services/settings.service';

describe('settings.service', () => {
  beforeEach(() => jest.clearAllMocks());

  it('exportMyData returns rpc data', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValue({ data: { foo: 1 }, error: null });
    const result = await exportMyData();
    expect(supabase.rpc).toHaveBeenCalledWith('export_my_data');
    expect(result).toEqual({ foo: 1 });
  });

  it('deleteMyAccount invokes edge function then delegates to auth signOut wrapper', async () => {
    (supabase.functions.invoke as jest.Mock).mockResolvedValue({ data: 'ok', error: null });
    (signOut as jest.Mock).mockResolvedValue(undefined);
    await deleteMyAccount();
    expect(supabase.functions.invoke).toHaveBeenCalledWith('delete-account', { method: 'POST' });
    expect(signOut).toHaveBeenCalled();
    // Wrapper handled cleanup — fallback should NOT have fired.
    expect(queryClient.clear).not.toHaveBeenCalled();
    expect(useFeedFiltersStore.getState).not.toHaveBeenCalled();
  });

  it('deleteMyAccount throws on edge function error and skips signOut', async () => {
    (supabase.functions.invoke as jest.Mock).mockResolvedValue({
      data: null,
      error: { message: 'bad' },
    });
    await expect(deleteMyAccount()).rejects.toThrow('bad');
    expect(signOut).not.toHaveBeenCalled();
  });

  it('deleteMyAccount runs full fallback cleanup if signOut fails post-deletion', async () => {
    (supabase.functions.invoke as jest.Mock).mockResolvedValue({ data: 'ok', error: null });
    (signOut as jest.Mock).mockRejectedValue(new Error('no session'));
    const feedClear = jest.fn();
    const profileReset = jest.fn();
    const onboardingReset = jest.fn();
    (useFeedFiltersStore.getState as jest.Mock).mockReturnValue({ clear: feedClear });
    (useProfileNudgeStore.getState as jest.Mock).mockReturnValue({ reset: profileReset });
    (useOnboardingDraft.getState as jest.Mock).mockReturnValue({ reset: onboardingReset });
    await deleteMyAccount();
    expect(queryClient.clear).toHaveBeenCalled();
    expect(feedClear).toHaveBeenCalled();
    expect(profileReset).toHaveBeenCalled();
    expect(onboardingReset).toHaveBeenCalled();
    expect(useTelemetryStore.setState).toHaveBeenCalledWith({
      analyticsEnabled: false,
      crashReportsEnabled: false,
    });
  });
});
