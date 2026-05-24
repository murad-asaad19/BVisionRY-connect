import { View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { SegmentedControl, type SegmentedOption } from '~/components/ui/SegmentedControl';

type Segment = 'received' | 'sent';

type Props = {
  active: Segment;
  onChange: (next: Segment) => void;
};

export function InboxTabs({ active, onChange }: Props) {
  const { t } = useTranslation();
  const options: SegmentedOption[] = [
    {
      value: 'received',
      label: t('intros.tabs.received'),
      testID: 'inbox-segment-received',
    },
    {
      value: 'sent',
      label: t('intros.tabs.sent'),
      testID: 'inbox-segment-sent',
    },
  ];
  return (
    <View testID="inbox-tabs" className="px-gutter pt-3 pb-2">
      <SegmentedControl
        options={options}
        value={active}
        onChange={(v) => onChange(v as Segment)}
      />
    </View>
  );
}
