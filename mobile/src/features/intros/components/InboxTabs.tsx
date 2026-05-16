import { View, Text, Pressable } from 'react-native';

type Segment = 'received' | 'sent';

type Props = {
  active: Segment;
  onChange: (next: Segment) => void;
};

export function InboxTabs({ active, onChange }: Props) {
  return (
    <View testID="inbox-tabs" className="flex-row border-b border-border">
      {[
        { key: 'received' as const, label: 'Received', testID: 'inbox-segment-received' },
        { key: 'sent' as const, label: 'Sent', testID: 'inbox-segment-sent' },
      ].map((tab) => {
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
