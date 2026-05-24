import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

export type NotificationKind = Database['public']['Enums']['notification_kind'];
export type NotificationChannel = Database['public']['Enums']['notification_channel'];

export type NotificationPrefRow = Database['public']['Tables']['notification_preferences']['Row'];

/**
 * Notification kinds surfaced in the settings UI.
 *
 * `goal_staleness` is intentionally omitted — the corresponding trigger isn't
 * shipped yet, so showing a toggle the user can flip without effect would be
 * misleading. The Banner inside `NotificationPrefsSection` calls this out
 * explicitly. Re-add `goal_staleness` once the trigger lands.
 *
 * Labels live in i18n (`settings.notif.kind.*`) — consumers should map by
 * `value`, not by any string in this module.
 */
export const NOTIFICATION_KINDS: { value: NotificationKind }[] = [
  { value: 'intro_received' },
  { value: 'intro_accepted' },
  { value: 'message_received' },
  { value: 'voice_received' },
  { value: 'meeting_proposal' },
  { value: 'meeting_confirmed' },
  { value: 'meeting_reminder' },
  { value: 'daily_matches_ready' },
];

export const NOTIFICATION_CHANNELS: NotificationChannel[] = ['push', 'email', 'in_app'];

export type PrefMap = Record<string, boolean>;

function keyOf(kind: NotificationKind, channel: NotificationChannel): string {
  return `${kind}:${channel}`;
}

export async function fetchNotificationPrefs(userId: string): Promise<PrefMap> {
  const { data, error } = await supabase
    .from('notification_preferences')
    .select('kind, channel, enabled')
    .eq('user_id', userId);
  if (error) throw new Error(error.message);
  const out: PrefMap = {};
  (data ?? []).forEach((r) => {
    out[keyOf(r.kind, r.channel)] = r.enabled;
  });
  return out;
}

export function isPrefEnabled(
  prefs: PrefMap,
  kind: NotificationKind,
  channel: NotificationChannel
): boolean {
  const v = prefs[keyOf(kind, channel)];
  return v === undefined ? true : v;
}

export async function setNotificationPref(params: {
  userId: string;
  kind: NotificationKind;
  channel: NotificationChannel;
  enabled: boolean;
}): Promise<void> {
  const { error } = await supabase.from('notification_preferences').upsert(
    {
      user_id: params.userId,
      kind: params.kind,
      channel: params.channel,
      enabled: params.enabled,
    },
    { onConflict: 'user_id,kind,channel' }
  );
  if (error) throw new Error(error.message);
}
