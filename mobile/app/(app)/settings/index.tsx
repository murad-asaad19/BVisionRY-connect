import { Alert, ScrollView, View } from 'react-native';
import { router, Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { SettingsRow } from '~/components/ui/SettingsRow';
import { Button } from '~/components/ui/Button';
import { useBlockedUsers } from '~/features/privacy/hooks/useBlockedUsers';
import { signOut } from '~/features/auth/services/auth.service';

type RowDef = {
  key: string;
  labelKey: string;
  descKey: string;
  descParams?: Record<string, string | number>;
  path: string;
};

export default function SettingsHomeScreen() {
  const { t } = useTranslation();
  const blocked = useBlockedUsers();
  const blockedCount = blocked.data?.length ?? 0;

  const rows: RowDef[] = [
    {
      key: 'account',
      labelKey: 'settings.account',
      descKey: 'settings.accountDesc',
      path: '/(app)/settings/account',
    },
    {
      key: 'privacy',
      labelKey: 'settings.privacy',
      descKey: 'settings.privacyDesc',
      path: '/(app)/settings/privacy',
    },
    {
      key: 'notifications',
      labelKey: 'settings.notifications',
      descKey: 'settings.notificationsDesc',
      path: '/(app)/settings/notifications',
    },
    {
      key: 'verification',
      labelKey: 'settings.verification',
      descKey: 'settings.verificationDesc',
      path: '/(app)/settings/verification',
    },
    {
      key: 'office-hours',
      labelKey: 'officeHours.settings.title',
      descKey: 'officeHours.settings.enableHelp',
      path: '/(app)/settings/office-hours',
    },
    {
      key: 'blocked-users',
      labelKey: 'settings.blockedUsers',
      descKey: 'settings.blockedUsersDesc',
      descParams: { count: blockedCount },
      path: '/(app)/settings/blocked-users',
    },
    {
      key: 'help',
      labelKey: 'settings.help',
      descKey: 'settings.helpDesc',
      path: '/(app)/settings/help',
    },
  ];

  return (
    <View testID="settings-screen" className="flex-1 bg-surface">
      <Stack.Screen options={{ title: t('settings.title') }} />
      <ScrollView className="flex-1">
        <View className="w-full max-w-2xl mx-auto py-2">
          <View className="mx-3 my-2 rounded-[10px] overflow-hidden border border-border bg-white">
            {rows.map((r, i) => (
              <SettingsRow
                key={r.key}
                testID={`settings-row-${r.key}`}
                label={t(r.labelKey)}
                description={t(r.descKey, r.descParams)}
                onPress={() => router.push(r.path as never)}
                isFirst={i === 0}
                isLast={i === rows.length - 1}
              />
            ))}
          </View>

          <View className="px-3.5 py-4">
            <Button
              testID="settings-sign-out"
              variant="outline-danger"
              onPress={() => {
                Alert.alert(
                  t('settings.signOutConfirm.title'),
                  t('settings.signOutConfirm.body'),
                  [
                    { text: t('common.cancel'), style: 'cancel' },
                    {
                      text: t('settings.signOut'),
                      style: 'destructive',
                      onPress: () => {
                        signOut().catch((e) =>
                          console.warn('[settings] sign-out failed', e)
                        );
                      },
                    },
                  ]
                );
              }}
            >
              {t('settings.signOut')}
            </Button>
          </View>
        </View>
      </ScrollView>
    </View>
  );
}
