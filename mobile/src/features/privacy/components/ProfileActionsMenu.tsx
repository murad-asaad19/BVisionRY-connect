import { useState } from 'react';
import { View, Text, Pressable, Alert } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { useBlockUser } from '~/features/privacy/hooks/useBlockUser';
import { ReportModal } from '~/features/privacy/components/ReportModal';

type Props = { targetUserId: string; targetHandle: string };

export function ProfileActionsMenu({ targetUserId, targetHandle }: Props) {
  const { t } = useTranslation();
  const [open, setOpen] = useState(false);
  const [showReport, setShowReport] = useState(false);
  const block = useBlockUser();

  const handleBlock = () => {
    block.mutate(targetUserId, {
      onSuccess: () => router.back(),
    });
  };

  const confirmBlock = () => {
    setOpen(false);
    Alert.alert(
      t('privacy.blockConfirm.title', { handle: targetHandle }),
      t('privacy.blockConfirm.body'),
      [
        { text: t('common.cancel'), style: 'cancel' },
        { text: t('privacy.block'), style: 'destructive', onPress: handleBlock },
      ]
    );
  };

  return (
    <>
      <Pressable
        testID="profile-actions-trigger"
        onPress={() => setOpen((v) => !v)}
        accessibilityRole="button"
        accessibilityLabel={t('privacy.openActions')}
        className="self-end px-3 py-2"
      >
        <Text className="text-body text-lg">⋯</Text>
      </Pressable>
      {open && (
        <View
          testID="profile-actions-menu"
          className="absolute right-2 top-12 bg-white border border-border rounded-xl py-2 z-40"
        >
          <Pressable
            testID="profile-actions-block"
            disabled={block.isPending}
            onPress={confirmBlock}
            className="px-4 py-2"
          >
            <Text className="text-body">{t('privacy.blockUser')}</Text>
          </Pressable>
          <Pressable
            testID="profile-actions-report"
            onPress={() => {
              setOpen(false);
              setShowReport(true);
            }}
            className="px-4 py-2"
          >
            <Text className="text-body">{t('privacy.report')}</Text>
          </Pressable>
        </View>
      )}
      <ReportModal
        visible={showReport}
        targetType="profile"
        targetId={targetUserId}
        onClose={() => setShowReport(false)}
      />
    </>
  );
}
