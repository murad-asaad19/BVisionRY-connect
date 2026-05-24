import { View } from 'react-native';
import { TopBar } from '~/components/ui/TopBar';
import { useTranslation } from 'react-i18next';
import { OpportunityFeed } from '~/features/opportunities/components/OpportunityFeed';

export default function OpportunitiesIndexRoute() {
  const { t } = useTranslation();
  return (
    <View className="flex-1 bg-surface">
      <TopBar title={t('opportunities.feed.title')} />
      <OpportunityFeed />
    </View>
  );
}
