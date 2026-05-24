import { View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { TopBar } from '~/components/ui/TopBar';
import { OpportunityFeed } from '~/features/opportunities/components/OpportunityFeed';

/**
 * Tab entry for Opportunities. Expo Router's tabs are file-based, so this
 * file mounts the feed directly. Detail / new live under
 * `mobile/app/(app)/opportunities/*` outside the tabs group so they can
 * push onto the stack with a back button.
 */
export default function OpportunitiesTabRoute() {
  const { t } = useTranslation();
  return (
    <View testID="opportunities-tab" className="flex-1 bg-surface">
      <TopBar title={t('opportunities.feed.title')} />
      <OpportunityFeed />
    </View>
  );
}
