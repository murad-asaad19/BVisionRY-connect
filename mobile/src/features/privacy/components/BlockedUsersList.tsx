import { View, Text, Image, FlatList } from 'react-native';
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

function Header() {
  const { t } = useTranslation();
  return (
    <View>
      <Text className="font-display-semibold text-muted text-xs uppercase tracking-wide mb-2">
        {t('settings.blockedUsers')}
      </Text>
      <Text className="font-body text-[11px] text-muted mb-3 leading-snug">
        {t('privacy.blockedListHint')}
      </Text>
    </View>
  );
}

export function BlockedUsersList() {
  const { t } = useTranslation();
  const q = useBlockedUsers();
  const unblock = useUnblockUser();

  return (
    <QueryState query={q}>
      {(rows) => (
        <FlatList
          testID="blocked-users-list"
          data={rows}
          keyExtractor={(r) => r.blocked_id}
          className="flex-1"
          contentContainerStyle={{ padding: 16, maxWidth: 672, width: '100%', alignSelf: 'center' }}
          ListHeaderComponent={Header}
          ListEmptyComponent={
            <Text className="text-muted text-sm">{t('privacy.blockedListEmpty')}</Text>
          }
          renderItem={({ item: r }) => (
            <View
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
                <Text className="text-muted text-xs mt-0.5">
                  {t('privacy.blockedAt', { date: fmtDate(r.created_at) })}
                </Text>
              </View>
              <Button
                testID={`unblock-${r.handle}`}
                variant="outline"
                size="small"
                fullWidth={false}
                disabled={unblock.isPending}
                onPress={() => unblock.mutate(r.blocked_id)}
              >
                {t('privacy.unblock')}
              </Button>
            </View>
          )}
        />
      )}
    </QueryState>
  );
}
