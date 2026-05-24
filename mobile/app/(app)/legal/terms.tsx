import { ScrollView, Text, View } from 'react-native';
import { Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';

export default function TermsOfServiceScreen() {
  const { t } = useTranslation();
  const title = t('legal.terms.title');
  const body = t('legal.terms.body');
  const paragraphs = body.split(/\n\n+/);
  return (
    <View className="flex-1 bg-surface">
      <Stack.Screen options={{ title, headerShown: true }} />
      <ScrollView testID="terms-screen" className="px-6 pt-4">
        <Text className="text-body text-xl font-semibold mb-3">{title}</Text>
        {paragraphs.map((p, i) => (
          <Text
            key={i}
            className={`text-muted ${i === paragraphs.length - 1 ? 'mb-8' : 'mb-3'}`}
          >
            {p}
          </Text>
        ))}
      </ScrollView>
    </View>
  );
}
