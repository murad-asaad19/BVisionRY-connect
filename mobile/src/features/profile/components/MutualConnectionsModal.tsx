import { View, Text, ScrollView } from 'react-native';
import { router } from 'expo-router';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { BottomSheet } from '~/components/ui/Modal';
import { UserCard } from '~/components/ui/UserCard';
import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

type ProfileRow = Database['public']['Tables']['profiles']['Row'];
type MutualProfile = Pick<
  ProfileRow,
  'id' | 'handle' | 'name' | 'photo_url' | 'primary_role' | 'headline'
>;

type Props = {
  visible: boolean;
  onClose: () => void;
  /** Up to 5 user ids — returned by get_profile_signals. */
  userIds: string[];
};

async function fetchMutualProfiles(userIds: string[]): Promise<MutualProfile[]> {
  if (userIds.length === 0) return [];
  const { data, error } = await supabase
    .from('profiles')
    .select('id, handle, name, photo_url, primary_role, headline')
    .in('id', userIds);
  if (error) throw new Error(error.message);
  // Preserve the RPC's ordering (recency) — `.in()` returns DB order which
  // is not guaranteed to match the input array.
  const byId = new Map((data ?? []).map((p) => [p.id, p]));
  return userIds.map((id) => byId.get(id)).filter((p): p is MutualProfile => Boolean(p));
}

export function MutualConnectionsModal({ visible, onClose, userIds }: Props) {
  const { t } = useTranslation();
  // Stable key by joined ids — the list is small (≤5) and rarely changes
  // while the modal is open, so we don't need a Set-based key.
  const key = userIds.join(',');
  const query = useQuery({
    queryKey: ['profileSignals', 'mutualProfiles', key],
    queryFn: () => fetchMutualProfiles(userIds),
    enabled: visible && userIds.length > 0,
    staleTime: 5 * 60 * 1000,
  });

  const profiles = query.data ?? [];

  return (
    <BottomSheet visible={visible} onClose={onClose} testID="mutual-connections-modal">
      <Text className="font-display-bold text-[16px] text-navy mb-3">
        {t('profile.signals.mutualModalTitle')}
      </Text>
      <ScrollView style={{ maxHeight: 420 }}>
        {profiles.length === 0 ? (
          <Text
            testID="mutual-connections-empty"
            className="font-body text-[13px] text-muted text-center py-4"
          >
            {t('profile.signals.mutualModalEmpty')}
          </Text>
        ) : (
          <View className="gap-2">
            {profiles.map((p) => (
              <UserCard
                key={p.id}
                testID={`mutual-card-${p.handle ?? p.id}`}
                name={p.name ?? '?'}
                handle={p.handle ?? ''}
                primaryRole={p.primary_role ?? ''}
                photoUrl={p.photo_url ?? null}
                headline={p.headline}
                onPress={() => {
                  if (!p.handle) return;
                  onClose();
                  router.push(`/p/${p.handle}` as never);
                }}
              />
            ))}
          </View>
        )}
      </ScrollView>
    </BottomSheet>
  );
}
