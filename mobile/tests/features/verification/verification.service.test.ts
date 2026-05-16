jest.mock('~/lib/supabase/client', () => ({
  supabase: {
    rpc: jest.fn(),
    auth: {
      linkIdentity: jest.fn(),
      unlinkIdentity: jest.fn(),
      getUser: jest.fn(),
    },
  },
}));

import { supabase } from '~/lib/supabase/client';
import {
  setGithubVerification,
  clearGithubVerification,
  beginGithubOAuth,
  extractGithubIdentity,
} from '~/features/verification/services/verification.service';

describe('verification.service', () => {
  beforeEach(() => jest.clearAllMocks());

  it('setGithubVerification calls RPC with username+id', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: {}, error: null });
    await setGithubVerification('octocat', 12345);
    expect(supabase.rpc).toHaveBeenCalledWith('set_github_verification', {
      p_github_username: 'octocat',
      p_github_id: 12345,
    });
  });

  it('setGithubVerification throws on error', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: { message: 'oops' } });
    await expect(setGithubVerification('octocat', 12345)).rejects.toThrow('oops');
  });

  it('clearGithubVerification calls RPC', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: {}, error: null });
    await clearGithubVerification();
    expect(supabase.rpc).toHaveBeenCalledWith('clear_github_verification');
  });

  it('beginGithubOAuth calls linkIdentity', async () => {
    (supabase.auth.linkIdentity as jest.Mock).mockResolvedValueOnce({ data: {}, error: null });
    await beginGithubOAuth('bvisionryconnect://auth/callback');
    expect(supabase.auth.linkIdentity).toHaveBeenCalledWith({
      provider: 'github',
      options: { redirectTo: 'bvisionryconnect://auth/callback' },
    });
  });

  it('extractGithubIdentity finds github identity in user.identities', () => {
    const user = {
      identities: [
        { provider: 'email', identity_data: {} },
        {
          provider: 'github',
          identity_data: { user_name: 'octocat', provider_id: '12345' },
        },
      ],
    };
    expect(extractGithubIdentity(user as any)).toEqual({ username: 'octocat', id: 12345 });
  });

  it('extractGithubIdentity returns null when no github identity', () => {
    expect(extractGithubIdentity({ identities: [] } as any)).toBeNull();
  });
});
