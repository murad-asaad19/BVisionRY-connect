import { Alert, ScrollView, View, Text } from 'react-native';
import { Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { useCurrentUserProfile } from '~/features/profile/hooks/useCurrentUserProfile';
import { useConnectGithub } from '~/features/verification/hooks/useConnectGithub';
import { useDisconnectGithub } from '~/features/verification/hooks/useDisconnectGithub';
import { QueryState } from '~/components/ui/QueryState';
import { Button } from '~/components/ui/Button';
import { Banner } from '~/components/ui/Banner';
import { SettingsRow } from '~/components/ui/SettingsRow';
import { Pill } from '~/components/ui/Pill';
import type { Database } from '~/lib/supabase/types.gen';

type RoleKind = Database['public']['Enums']['role_kind'];

// Proof configurations are role-scoped so labels/descriptions can diverge per
// role over time. Strings are resolved at render-time via i18n keys
// `verification.proofs.{role}.{key}.{label,description}`.
const PROOFS_BY_ROLE: Partial<Record<RoleKind, ReadonlyArray<string>>> = {
  founder: ['domain', 'team_page'],
  investor: ['domain', 'crunchbase', 'portfolio'],
  // GitHub is the wired-up proof; the Connect button lives in the row below.
  builder: ['github'],
  leader: ['domain'],
};

export default function VerificationSubScreen() {
  const { t } = useTranslation();
  const profileQ = useCurrentUserProfile();
  const connect = useConnectGithub();
  const disconnect = useDisconnectGithub();

  return (
    <View testID="settings-screen" className="flex-1 bg-surface">
      <Stack.Screen options={{ title: t('settings.verification') }} />
      <QueryState query={profileQ} isEmpty={(p) => p === null}>
        {(profile) =>
          profile === null ? null : (
            <ScrollView className="flex-1">
              <View className="w-full max-w-2xl mx-auto p-4">
                <View className="mb-3">
                  <Banner variant="muted">{t('verification.rankingBoost')}</Banner>
                </View>

                {(profile.roles ?? []).map((role) => {
                  const proofs = PROOFS_BY_ROLE[role] ?? [];
                  if (proofs.length === 0) return null;
                  return (
                    <View key={role} className="mb-4">
                      <Text className="font-display-bold text-[10px] uppercase tracking-wide text-muted mb-1.5 px-1">
                        {t(`discovery.roles.${role}`)}
                      </Text>
                      <View className="rounded-[10px] overflow-hidden border border-border">
                        {proofs.map((proofKey, i) => {
                          const isFirst = i === 0;
                          const isLast = i === proofs.length - 1;
                          const isGithub = proofKey === 'github';
                          const ghConnected = !!profile.verified_github_username;
                          const label = t(`verification.proofs.${role}.${proofKey}.label`);
                          const description = t(
                            `verification.proofs.${role}.${proofKey}.description`
                          );
                          if (isGithub) {
                            return (
                              <SettingsRow
                                key={proofKey}
                                testID={
                                  ghConnected
                                    ? 'settings-github-connected'
                                    : `verify-${role}-${proofKey}`
                                }
                                label={label}
                                description={
                                  ghConnected
                                    ? `@${profile.verified_github_username}`
                                    : description
                                }
                                isFirst={isFirst}
                                isLast={isLast}
                                rightSlot={
                                  ghConnected ? (
                                    <View className="flex-row items-center gap-2">
                                      <Pill variant="success">{t('verification.verifiedPill')}</Pill>
                                      <Button
                                        testID="settings-github-disconnect"
                                        variant="outline"
                                        size="small"
                                        fullWidth={false}
                                        onPress={() =>
                                          Alert.alert(
                                            t('verification.disconnectConfirm.title'),
                                            t('verification.disconnectConfirm.body'),
                                            [
                                              {
                                                text: t('verification.disconnectConfirm.cancel'),
                                                style: 'cancel',
                                              },
                                              {
                                                text: t('verification.disconnectConfirm.confirm'),
                                                style: 'destructive',
                                                onPress: () => disconnect.mutate(),
                                              },
                                            ]
                                          )
                                        }
                                      >
                                        {t('verification.disconnect')}
                                      </Button>
                                    </View>
                                  ) : (
                                    <Button
                                      testID="settings-github-connect"
                                      variant="primary"
                                      size="small"
                                      fullWidth={false}
                                      onPress={() => connect.mutate()}
                                      loading={connect.isPending}
                                    >
                                      {t('verification.connect')}
                                    </Button>
                                  )
                                }
                              />
                            );
                          }
                          return (
                            <SettingsRow
                              key={proofKey}
                              testID={`verify-${role}-${proofKey}`}
                              label={label}
                              description={description}
                              isFirst={isFirst}
                              isLast={isLast}
                              rightSlot={<Pill variant="muted">{t('verification.comingSoon')}</Pill>}
                            />
                          );
                        })}
                      </View>
                    </View>
                  );
                })}
              </View>
            </ScrollView>
          )
        }
      </QueryState>
    </View>
  );
}
