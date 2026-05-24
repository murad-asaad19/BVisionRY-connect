import { View, Text, Switch } from 'react-native';
import { useTranslation } from 'react-i18next';
import {
  useNotificationPrefs,
  useSetNotificationPref,
} from '~/features/settings/hooks/useNotificationPrefs';
import {
  NOTIFICATION_KINDS,
  NOTIFICATION_CHANNELS,
  isPrefEnabled,
} from '~/features/settings/services/notificationPrefs.service';
import { Banner } from '~/components/ui/Banner';

/**
 * Notification prefs reformatted as one card per kind, with one toggle row per
 * channel inside each card. Replaces the prior 4-column table that overflowed
 * at narrow viewports (audit P2-3). Per-row labels are clearer than column
 * headers and accommodate longer channel names in non-English locales without
 * cramping.
 */
export function NotificationPrefsSection() {
  const { t } = useTranslation();
  const prefsQ = useNotificationPrefs();
  const setPref = useSetNotificationPref();
  const prefs = prefsQ.data ?? {};

  return (
    <View testID="notification-prefs-section" className="px-gutter py-2">
      {NOTIFICATION_KINDS.map((kind) => (
        <View key={kind.value} className="mb-4">
          <Text className="font-display-bold text-body-xs uppercase tracking-wide text-muted mb-1.5 px-1">
            {t(`settings.notif.kind.${kind.value}`)}
          </Text>
          <View className="rounded-[10px] overflow-hidden border border-border bg-white">
            {NOTIFICATION_CHANNELS.map((channel, ci) => {
              const enabled = isPrefEnabled(prefs, kind.value, channel);
              const isLast = ci === NOTIFICATION_CHANNELS.length - 1;
              return (
                <View
                  key={channel}
                  className={`flex-row items-center justify-between px-card-lg py-card ${
                    isLast ? '' : 'border-b border-slate-100'
                  }`}
                >
                  <Text className="font-body text-body-md text-body">
                    {t(`settings.notif.channel.${channel}`)}
                  </Text>
                  <Switch
                    testID={`pref-${kind.value}-${channel}`}
                    value={enabled}
                    onValueChange={(v) =>
                      setPref.mutate({ kind: kind.value, channel, enabled: v })
                    }
                  />
                </View>
              );
            })}
          </View>
        </View>
      ))}
      <View className="mt-2">
        <Banner variant="muted">{t('settings.notif.decayBanner')}</Banner>
      </View>
    </View>
  );
}
