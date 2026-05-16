import { useLocalSearchParams } from 'expo-router';
import { IntroDetailView } from '~/features/intros/components/IntroDetailView';

export default function IntroDetailRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();
  return <IntroDetailView id={id ?? ''} />;
}
