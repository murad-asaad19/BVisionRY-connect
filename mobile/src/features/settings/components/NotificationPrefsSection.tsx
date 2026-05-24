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

export function NotificationPrefsSection() {
  const { t } = useTranslation();
  const prefsQ = useNotificationPrefs();
  const setPref = useSetNotificationPref();
  const prefs = prefsQ.data ?? {};

  return (
    <View testID="notification-prefs-section" className="px-3 py-2">
      <View className="rounded-[10px] overflow-hidden border border-border bg-white">
        {/* Header row */}
        <View className="flex-row items-center px-3 py-2 border-b border-slate-100 bg-slate-50">
          <Text className="flex-1 font-display-bold text-[10px] uppercase tracking-wide text-muted">
            {t('settings.notif.header')}
          </Text>
          {NOTIFICATION_CHANNELS.map((c) => (
            <Text
              key={c}
              className="w-16 text-center font-display-bold text-[10px] uppercase tracking-wide text-muted"
            >
              {t(`settings.notif.channel.${c}`)}
            </Text>
          ))}
        </View>
        {/* Body rows */}
        {NOTIFICATION_KINDS.map((kind, i) => (
          <View
            key={kind.value}
            className={`flex-row items-center px-3 py-2 ${
              i === NOTIFICATION_KINDS.length - 1 ? '' : 'border-b border-slate-100'
            }`}
          >
            <Text className="flex-1 font-display-semibold text-[12px] text-body" numberOfLines={2}>
              {t(`settings.notif.kind.${kind.value}`)}
            </Text>
            {NOTIFICATION_CHANNELS.map((c) => {
              const enabled = isPrefEnabled(prefs, kind.value, c);
              return (
                <View key={c} className="w-16 items-center">
                  <Switch
                    testID={`pref-${kind.value}-${c}`}
                    value={enabled}
                    onValueChange={(v) =>
                      setPref.mutate({ kind: kind.value, channel: c, enabled: v })
                    }
                  />
                </View>
              );
            })}
          </View>
        ))}
      </View>
      <View className="mt-3">
        <Banner variant="muted">{t('settings.notif.decayBanner')}</Banner>
      </View>
    </View>
  );
}
