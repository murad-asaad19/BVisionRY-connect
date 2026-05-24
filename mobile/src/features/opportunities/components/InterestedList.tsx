import { View, Text, FlatList } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { useInterestedList } from '~/features/opportunities/hooks/useInterestedList';
import { UserCard } from '~/components/ui/UserCard';
import { QueryState } from '~/components/ui/QueryState';

type Props = {
  opportunityId: string;
  /** Only the opportunity's author may call list_interested. */
  isAuthor: boolean;
};

export function InterestedList({ opportunityId, isAuthor }: Props) {
  const { t } = useTranslation();
  const query = useInterestedList({ opportunityId, isAuthor });

  if (!isAuthor) return null;

  return (
    <View testID="interested-list" className="flex-1 bg-surface">
      <QueryState
        query={query}
        isEmpty={(data) => data.length === 0}
        emptyText={t('opportunities.interested.empty')}
      >
        {(rows) => (
          <FlatList
            testID="interested-list-flatlist"
            data={rows}
            keyExtractor={(r) => r.userId}
            contentContainerStyle={{ padding: 12, gap: 8 }}
            renderItem={({ item }) => (
              <View testID={`interested-row-${item.userId}`}>
                <UserCard
                  name={item.name}
                  handle={item.handle}
                  primaryRole={item.primaryRole ?? ''}
                  photoUrl={item.photoUrl}
                  onPress={() =>
                    router.push({
                      pathname: '/(app)/p/[handle]',
                      params: { handle: item.handle },
                    })
                  }
                />
                {item.note ? (
                  <Text className="font-body text-[12px] text-body mt-1 px-2">
                    {item.note}
                  </Text>
                ) : null}
              </View>
            )}
          />
        )}
      </QueryState>
    </View>
  );
}
