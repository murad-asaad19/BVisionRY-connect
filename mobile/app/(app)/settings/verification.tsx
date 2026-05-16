import { useEffect } from 'react';
import { Alert, ScrollView, View, Text } from 'react-native';
import { Stack } from 'expo-router';
import { useQueryClient } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { useCurrentUserProfile } from '~/features/profile/hooks/useCurrentUserProfile';
import {
  useConnectGithub,
  finishGithubConnect,
} from '~/features/verification/hooks/useConnectGithub';
import { useDisconnectGithub } from '~/features/verification/hooks/useDisconnectGithub';
import { QueryState } from '~/components/ui/QueryState';
import { Button } from '~/components/ui/Button';
import { Banner } from '~/components/ui/Banner';
import { SettingsRow } from '~/components/ui/SettingsRow';
import { Pill } from '~/components/ui/Pill';
import type { Database } from '~/lib/supabase/types.gen';

type RoleKind = Database['public']['Enums']['role_kind'];

type ProofConfig = {
  key: string;
  label: string;
  description: string;
};

const PROOFS_BY_ROLE: Partial<Record<RoleKind, ProofConfig[]>> = {
  founder: [
    { key: 'domain', label: 'Domain email', description: 'Verify with a custom-domain email.' },
    { key: 'team_page', label: '/team page', description: 'Listed on your company team page.' },
  ],
  investor: [
    { key: 'domain', label: 'Domain email', description: 'Verify with a custom-domain email.' },
    {
      key: 'crunchbase',
      label: 'Crunchbase profile',
      description: 'Link a public Crunchbase profile.',
    },
    {
      key: 'portfolio',
      label: 'Portfolio listings',
      description: 'Public portfolio that lists you.',
    },
  ],
  builder: [
    // GitHub is the wired-up proof; placeholder description, the Connect button lives in the row below.
    {
      key: 'github',
      label: 'GitHub',
      description: 'Verify a public commit signed with the connected account.',
    },
  ],
  leader: [
    { key: 'domain', label: 'Domain email', description: 'Verify with a custom-domain email.' },
  ],
};

export default function VerificationSubScreen() {
  const { t } = useTranslation();
  const profileQ = useCurrentUserProfile();
  const connect = useConnectGithub();
  const disconnect = useDisconnectGithub();
  const qc = useQueryClient();

  useEffect(() => {
    if (connect.isSuccess) {
      (async () => {
        try {
          await finishGithubConnect();
          await qc.invalidateQueries({ queryKey: ['profile'] });
        } catch (e) {
          Alert.alert('GitHub verification failed', (e as Error).message);
        }
      })();
    }
  }, [connect.isSuccess, qc]);

  return (
    <View testID="settings-screen" className="flex-1 bg-surface">
      <Stack.Screen options={{ title: t('settings.verification') }} />
      <QueryState query={profileQ} isEmpty={(p) => p === null}>
        {(profile) =>
          profile === null ? null : (
            <ScrollView className="flex-1">
              <View className="w-full max-w-2xl mx-auto p-4">
                <View className="mb-3">
                  <Banner variant="muted">
                    Verified roles earn a +15% ranking boost that ramps over 14 days.
                  </Banner>
                </View>

                {(profile.roles ?? []).map((role) => {
                  const proofs = PROOFS_BY_ROLE[role] ?? [];
                  if (proofs.length === 0) return null;
                  return (
                    <View key={role} className="mb-4">
                      <Text className="font-display-bold text-[10px] uppercase tracking-wide text-muted mb-1.5 px-1">
                        {role}
                      </Text>
                      <View className="rounded-[10px] overflow-hidden border border-border">
                        {proofs.map((proof, i) => {
                          const isFirst = i === 0;
                          const isLast = i === proofs.length - 1;
                          const isGithub = proof.key === 'github';
                          const ghConnected = !!profile.verified_github_username;
                          if (isGithub) {
                            return (
                              <SettingsRow
                                key={proof.key}
                                testID={
                                  ghConnected
                                    ? 'settings-github-connected'
                                    : `verify-${role}-${proof.key}`
                                }
                                label={proof.label}
                                description={
                                  ghConnected
                                    ? `@${profile.verified_github_username}`
                                    : proof.description
                                }
                                isFirst={isFirst}
                                isLast={isLast}
                                rightSlot={
                                  ghConnected ? (
                                    <View className="flex-row items-center gap-2">
                                      <Pill variant="success">Verified</Pill>
                                      <Button
                                        testID="settings-github-disconnect"
                                        variant="outline"
                                        size="small"
                                        fullWidth={false}
                                        onPress={() =>
                                          Alert.alert(
                                            'Disconnect GitHub?',
                                            'Your verified badge will be removed.',
                                            [
                                              { text: 'Cancel', style: 'cancel' },
                                              {
                                                text: 'Disconnect',
                                                style: 'destructive',
                                                onPress: () => disconnect.mutate(),
                                              },
                                            ]
                                          )
                                        }
                                      >
                                        Disconnect
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
                                      Connect
                                    </Button>
                                  )
                                }
                              />
                            );
                          }
                          return (
                            <SettingsRow
                              key={proof.key}
                              testID={`verify-${role}-${proof.key}`}
                              label={proof.label}
                              description={proof.description}
                              isFirst={isFirst}
                              isLast={isLast}
                              rightSlot={<Pill variant="muted">Coming soon</Pill>}
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
