import { View, Text, Switch, Alert } from 'react-native';
import { useTranslation } from 'react-i18next';
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
  const { t } = useTranslation();
  const profileQ = useCurrentUserProfile();
  const profile = profileQ.data;
  const setPrivate = useSetPrivateMode();
  const update = useUpdateProfileToggle(profile?.id);

  if (!profile) return null;

  const showToggleError = () => {
    Alert.alert(t('privacy.toggleFailed.title'), t('privacy.toggleFailed.body'));
  };

  return (
    <View testID="privacy-toggles-section" className="mb-4">
      <GroupHeading>{t('privacy.togglesGroup.discovery')}</GroupHeading>
      <View className="rounded-[10px] overflow-hidden border border-border">
        <Row
          testID="toggle-private-mode"
          label={t('privacy.toggle.privateModeLabel')}
          description={t('privacy.toggle.privateModeDesc')}
          value={profile.private_mode ?? false}
          onChange={(v) => setPrivate.mutate(v, { onError: showToggleError })}
          isFirst
          isLast
        />
      </View>

      <GroupHeading>{t('privacy.togglesGroup.chat')}</GroupHeading>
      <View className="rounded-[10px] overflow-hidden border border-border">
        <Row
          testID="toggle-read-receipts"
          label={t('privacy.toggle.readReceiptsLabel')}
          description={t('privacy.toggle.readReceiptsDesc')}
          value={profile.read_receipts_enabled ?? false}
          onChange={(v) =>
            update.mutate({ read_receipts_enabled: v }, { onError: showToggleError })
          }
          isFirst
          isLast
        />
      </View>

      <GroupHeading>{t('privacy.togglesGroup.safety')}</GroupHeading>
      <View className="rounded-[10px] overflow-hidden border border-border">
        <Row
          testID="toggle-public-investor-page"
          label={t('privacy.toggle.publicInvestorLabel')}
          description={t('privacy.toggle.publicInvestorDesc')}
          value={profile.public_investor_page ?? false}
          onChange={(v) =>
            update.mutate({ public_investor_page: v }, { onError: showToggleError })
          }
          isFirst
          isLast
        />
      </View>
    </View>
  );
}
