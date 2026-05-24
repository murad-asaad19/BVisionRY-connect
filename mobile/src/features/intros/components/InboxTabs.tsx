import { View, Text, Pressable } from 'react-native';
import { useTranslation } from 'react-i18next';

type Segment = 'received' | 'sent';

type Props = {
  active: Segment;
  onChange: (next: Segment) => void;
};

export function InboxTabs({ active, onChange }: Props) {
  const { t } = useTranslation();
  const tabs: { key: Segment; label: string; testID: string }[] = [
    { key: 'received', label: t('intros.tabs.received'), testID: 'inbox-segment-received' },
    { key: 'sent', label: t('intros.tabs.sent'), testID: 'inbox-segment-sent' },
  ];
  return (
    <View testID="inbox-tabs" className="flex-row border-b border-border">
      {tabs.map((tab) => {
        const isActive = active === tab.key;
        return (
          <Pressable
            key={tab.key}
            testID={tab.testID}
            onPress={() => onChange(tab.key)}
            accessibilityRole="button"
            accessibilityState={{ selected: isActive }}
            className={`flex-1 items-center py-3 border-b-2 ${
              isActive ? 'border-gold' : 'border-transparent'
            }`}
          >
            <Text
              className={`font-display-bold text-[13px] ${isActive ? 'text-navy' : 'text-muted'}`}
            >
              {tab.label}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}
