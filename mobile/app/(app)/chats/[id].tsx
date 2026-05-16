import { useLocalSearchParams } from 'expo-router';
import { ConversationScreen } from '~/features/chat/components/ConversationScreen';

export default function ConversationRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();
  return <ConversationScreen id={id ?? ''} />;
}
