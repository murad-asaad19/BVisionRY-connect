import { View, Text, Image } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useBlockedUsers } from '~/features/privacy/hooks/useBlockedUsers';
import { useUnblockUser } from '~/features/privacy/hooks/useUnblockUser';
import { QueryState } from '~/components/ui/QueryState';
import { Button } from '~/components/ui/Button';

function fmtDate(iso: string): string {
  try {
    return new Date(iso).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
  } catch {
    return iso;
  }
}

export function BlockedUsersList() {
  const { t } = useTranslation();
  const q = useBlockedUsers();
  const unblock = useUnblockUser();

  return (
    <View>
      <Text className="font-display-semibold text-muted text-xs uppercase tracking-wide mb-2">
        {t('settings.blockedUsers')}
      </Text>
      <Text className="font-body text-[11px] text-muted mb-3 leading-snug">
        Blocked users can never re-request a connection — even if you unblock.
      </Text>
      <QueryState
        query={q}
        isEmpty={(rows) => rows.length === 0}
        emptyFallback={<Text className="text-muted text-sm">You haven&apos;t blocked anyone.</Text>}
      >
        {(rows) => (
          <View testID="blocked-users-list">
            {rows.map((r) => (
              <View
                key={r.blocked_id}
                testID={`blocked-row-${r.handle}`}
                className="flex-row items-center bg-white border border-border rounded-xl p-3 mb-2"
              >
                {r.photo_url ? (
                  <Image source={{ uri: r.photo_url }} className="w-10 h-10 rounded-full mr-3" />
                ) : (
                  <View className="w-10 h-10 rounded-full bg-surface mr-3" />
                )}
                <View className="flex-1">
                  <Text className="text-body font-semibold">{r.name}</Text>
                  <Text className="text-muted text-sm">@{r.handle}</Text>
                  <Text className="text-muted text-xs mt-0.5">Blocked {fmtDate(r.created_at)}</Text>
                </View>
                <Button
                  testID={`unblock-${r.handle}`}
                  variant="outline"
                  size="small"
                  fullWidth={false}
                  disabled={unblock.isPending}
                  onPress={() => unblock.mutate(r.blocked_id)}
                >
                  Unblock
                </Button>
              </View>
            ))}
          </View>
        )}
      </QueryState>
    </View>
  );
}
