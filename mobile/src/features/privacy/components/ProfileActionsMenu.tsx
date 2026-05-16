import { useState } from 'react';
import { View, Text, Pressable } from 'react-native';
import { router } from 'expo-router';
import { useBlockUser } from '~/features/privacy/hooks/useBlockUser';
import { ReportModal } from '~/features/privacy/components/ReportModal';

type Props = { targetUserId: string; targetHandle: string };

export function ProfileActionsMenu({ targetUserId, targetHandle: _targetHandle }: Props) {
  const [open, setOpen] = useState(false);
  const [showReport, setShowReport] = useState(false);
  const block = useBlockUser();

  return (
    <>
      <Pressable
        testID="profile-actions-trigger"
        onPress={() => setOpen((v) => !v)}
        accessibilityRole="button"
        accessibilityLabel="Open profile actions"
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
            onPress={() => {
              setOpen(false);
              block.mutate(targetUserId, {
                onSuccess: () => router.back(),
              });
            }}
            className="px-4 py-2"
          >
            <Text className="text-body">Block User</Text>
          </Pressable>
          <Pressable
            testID="profile-actions-report"
            onPress={() => {
              setOpen(false);
              setShowReport(true);
            }}
            className="px-4 py-2"
          >
            <Text className="text-body">Report</Text>
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
