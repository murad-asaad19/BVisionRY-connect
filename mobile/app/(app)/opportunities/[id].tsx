import { useLocalSearchParams } from 'expo-router';
import { OpportunityDetailView } from '~/features/opportunities/components/OpportunityDetailView';

export default function OpportunityDetailRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();
  if (!id) return null;
  return <OpportunityDetailView opportunityId={id} />;
}
