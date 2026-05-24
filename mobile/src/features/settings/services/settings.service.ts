import { supabase } from '~/lib/supabase/client';
import { signOut } from '~/features/auth/services/auth.service';
import { queryClient } from '~/lib/query-client';
import { useFeedFiltersStore } from '~/features/discovery/store/feedFiltersStore';
import { useProfileNudgeStore } from '~/features/profile/store/profileNudgeStore';
import { useOnboardingDraft } from '~/features/onboarding/store/useOnboardingDraft';
import { useTelemetryStore } from '~/features/settings/store/telemetryStore';

export async function exportMyData(): Promise<unknown> {
  const { data, error } = await supabase.rpc('export_my_data');
  if (error) throw new Error(error.message);
  return data;
}

/**
 * Invokes the `delete-account` edge function (which deletes the auth user and
 * cascades all related rows server-side), then delegates to the auth wrapper
 * `signOut()` so the local query cache and persisted Zustand stores are wiped
 * and the next signed-in user starts from a clean slate.
 *
 * The session is already invalidated by the edge function, so the wrapper's
 * `supabase.auth.signOut()` call can surface a benign "no session" error
 * before its cleanup block runs. We swallow that and manually replicate the
 * wrapper's local-state scrubbing — cache + persisted stores must always be
 * cleared after account deletion, otherwise the next user on the same device
 * could briefly see the deleted user's filters / nudge timestamps / draft.
 *
 * If `auth.service.ts` ever exposes a `resetClientState()` helper, swap the
 * inline block for that and drop these imports.
 */
export async function deleteMyAccount(): Promise<void> {
  const { error } = await supabase.functions.invoke('delete-account', { method: 'POST' });
  if (error) throw new Error(error.message);
  try {
    await signOut();
  } catch (e) {
    console.warn('[settings] post-delete signOut failed; running fallback cleanup', e);
    queryClient.clear();
    try {
      useFeedFiltersStore.getState().clear();
      useProfileNudgeStore.getState().reset();
      useOnboardingDraft.getState().reset();
      // Telemetry resets to opted-out: the deleted user's preferences should
      // never bleed into whoever signs in next on the same device, and
      // opt-out is the safer fallback when we can't ask the next user yet.
      useTelemetryStore.setState({ analyticsEnabled: false, crashReportsEnabled: false });
    } catch (resetErr) {
      console.warn('[settings] fallback store reset failed', resetErr);
    }
  }
}
