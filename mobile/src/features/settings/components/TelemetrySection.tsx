import { View, Text, Switch } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useTelemetryStore } from '~/features/settings/store/telemetryStore';

export function TelemetrySection() {
  const { t } = useTranslation();
  const analyticsEnabled = useTelemetryStore((s) => s.analyticsEnabled);
  const crashReportsEnabled = useTelemetryStore((s) => s.crashReportsEnabled);
  const setAnalytics = useTelemetryStore((s) => s.setAnalytics);
  const setCrashReports = useTelemetryStore((s) => s.setCrashReports);

  return (
    <View className="mt-6">
      <Text className="font-display-semibold text-muted text-display-xs uppercase tracking-wide mb-2">
        {t('settings.telemetry')}
      </Text>
      <View className="flex-row items-center justify-between py-2">
        <Text className="font-body text-body-lg text-body">{t('settings.analytics')}</Text>
        <Switch testID="pref-analytics" value={analyticsEnabled} onValueChange={setAnalytics} />
      </View>
      <View className="flex-row items-center justify-between py-2">
        <Text className="font-body text-body-lg text-body">{t('settings.crashReports')}</Text>
        <Switch
          testID="pref-crash-reports"
          value={crashReportsEnabled}
          onValueChange={setCrashReports}
        />
      </View>
    </View>
  );
}
