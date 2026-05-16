import { View, Text, Switch } from 'react-native';
import { useCurrentUserProfile } from '~/features/profile/hooks/useCurrentUserProfile';
import {
  useSetPrivateMode,
  useUpdateProfileToggle,
} from '~/features/privacy/hooks/usePrivacyToggles';

type RowProps = {
  testID: string;
  label: string;
  description: string;
  value: boolean;
  onChange: (v: boolean) => void;
  isFirst?: boolean;
  isLast?: boolean;
};

function Row({ testID, label, description, value, onChange, isFirst, isLast }: RowProps) {
  const border = isLast ? '' : 'border-b border-slate-100';
  return (
    <View
      className={`bg-white px-3.5 py-3 flex-row items-center justify-between ${
        isFirst && isLast
          ? 'rounded-[10px]'
          : isFirst
            ? 'rounded-t-[10px]'
            : isLast
              ? 'rounded-b-[10px]'
              : ''
      } ${border}`}
    >
      <View className="flex-1 mr-2">
        <Text className="font-display-semibold text-[12px] text-body">{label}</Text>
        <Text className="font-body text-[10px] text-muted mt-0.5 leading-snug">{description}</Text>
      </View>
      <Switch testID={testID} value={value} onValueChange={onChange} />
    </View>
  );
}

function GroupHeading({ children }: { children: string }) {
  return (
    <Text className="font-display-bold text-[10px] text-muted uppercase tracking-wide mt-4 mb-1.5 px-1">
      {children}
    </Text>
  );
}

export function PrivacyTogglesSection() {
  const profileQ = useCurrentUserProfile();
  const profile = profileQ.data;
  const setPrivate = useSetPrivateMode();
  const update = useUpdateProfileToggle(profile?.id);

  if (!profile) return null;

  return (
    <View testID="privacy-toggles-section" className="mb-4">
      <GroupHeading>Discovery</GroupHeading>
      <View className="rounded-[10px] overflow-hidden border border-border">
        <Row
          testID="toggle-private-mode"
          label="Private mode"
          description="Hidden from feed, Daily matches, and search. Direct profile links still work."
          value={profile.private_mode ?? false}
          onChange={(v) => setPrivate.mutate(v)}
          isFirst
          isLast
        />
      </View>

      <GroupHeading>Chat</GroupHeading>
      <View className="rounded-[10px] overflow-hidden border border-border">
        <Row
          testID="toggle-read-receipts"
          label="Read receipts"
          description="Let others see when you've read their messages."
          value={profile.read_receipts_enabled ?? false}
          onChange={(v) => update.mutate({ read_receipts_enabled: v })}
          isFirst
          isLast
        />
      </View>

      <GroupHeading>Safety</GroupHeading>
      <View className="rounded-[10px] overflow-hidden border border-border">
        <Row
          testID="toggle-public-investor-page"
          label="Verified-Investor public page"
          description="Your public web page at connect.bvisionry.com/u/{handle}. Verified Investor profiles default to OFF."
          value={profile.public_investor_page ?? false}
          onChange={(v) => update.mutate({ public_investor_page: v })}
          isFirst
          isLast
        />
      </View>
    </View>
  );
}
