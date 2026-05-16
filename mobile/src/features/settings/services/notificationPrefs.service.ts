import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

export type NotificationKind = Database['public']['Enums']['notification_kind'];
export type NotificationChannel = Database['public']['Enums']['notification_channel'];

export type NotificationPrefRow = Database['public']['Tables']['notification_preferences']['Row'];

export const NOTIFICATION_KINDS: { value: NotificationKind; label: string }[] = [
  { value: 'intro_received', label: 'Incoming intro' },
  { value: 'intro_accepted', label: 'Accepted intro' },
  { value: 'message_received', label: 'New chat message' },
  { value: 'voice_received', label: 'Voice note' },
  { value: 'meeting_reminder', label: 'Meeting reminder' },
  { value: 'daily_matches_ready', label: 'Daily matches ready' },
  { value: 'goal_staleness', label: 'Goal-staleness nudge' },
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
