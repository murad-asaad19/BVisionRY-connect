import { useState } from 'react';
import { View, Text, Pressable } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { MoreHorizontal } from 'lucide-react-native';
import { useBlockUser } from '~/features/privacy/hooks/useBlockUser';
import { ReportModal } from '~/features/privacy/components/ReportModal';
import { IconButton } from '~/components/ui/IconButton';
import { useConfirm } from '~/components/ui/ConfirmDialog';

type Props = { targetUserId: string; targetHandle: string };

export function ProfileActionsMenu({ targetUserId, targetHandle }: Props) {
  const { t } = useTranslation();
  const [open, setOpen] = useState(false);
  const [showReport, setShowReport] = useState(false);
  const block = useBlockUser();
  const confirm = useConfirm();

  const confirmBlock = async () => {
    setOpen(false);
    const ok = await confirm({
      title: t('privacy.blockConfirm.title', { handle: targetHandle }),
      body: t('privacy.blockConfirm.body'),
      confirmLabel: t('privacy.block'),
      cancelLabel: t('common.cancel'),
      destructive: true,
      onConfirm: () =>
        new Promise<void>((resolve, reject) => {
          block.mutate(targetUserId, {
            onSuccess: () => {
              resolve();
            },
            onError: (e) => reject(e),
          });
        }),
    });
    if (ok) router.back();
  };

  return (
    <>
      <View className="self-end">
        <IconButton
          testID="profile-actions-trigger"
          icon={MoreHorizontal}
          label={t('privacy.openActions')}
          onPress={() => setOpen((v) => !v)}
        />
      </View>
      {open && (
        <View
          testID="profile-actions-menu"
          className="absolute right-2 top-12 bg-white border border-border rounded-xl py-2 z-40"
        >
          <Pressable
            testID="profile-actions-block"
            disabled={block.isPending}
            onPress={confirmBlock}
            className="px-4 py-2 active:bg-slate-100"
          >
            <Text className="font-body text-body-lg text-body">{t('privacy.blockUser')}</Text>
          </Pressable>
          <Pressable
            testID="profile-actions-report"
            onPress={() => {
              setOpen(false);
              setShowReport(true);
            }}
            className="px-4 py-2 active:bg-slate-100"
          >
            <Text className="font-body text-body-lg text-body">{t('privacy.report')}</Text>
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
