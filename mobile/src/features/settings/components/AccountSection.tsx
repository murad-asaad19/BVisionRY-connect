import { useState } from 'react';
import { View, Text, Pressable, Platform } from 'react-native';
import { useMutation } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { ChevronDown, ChevronRight } from 'lucide-react-native';
import * as FileSystem from 'expo-file-system';
import * as Sharing from 'expo-sharing';
import { deleteMyAccount, exportMyData } from '~/features/settings/services/settings.service';
import { Button } from '~/components/ui/Button';
import { useConfirm } from '~/components/ui/ConfirmDialog';
import { useToast } from '~/components/ui/Toast';
import { colors } from '~/theme/colors';

export function AccountSection() {
  const { t } = useTranslation();
  const confirm = useConfirm();
  const toast = useToast();
  const [exporting, setExporting] = useState(false);
  const [advancedOpen, setAdvancedOpen] = useState(false);

  const onExport = async () => {
    setExporting(true);
    try {
      const data = await exportMyData();
      const json = JSON.stringify(data, null, 2);

      if (Platform.OS === 'web') {
        // Browser download flow — synthesize an <a> + Blob.
        if (typeof window !== 'undefined' && 'Blob' in window && typeof document !== 'undefined') {
          const blob = new Blob([json], { type: 'application/json' });
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = 'my-data.json';
          a.click();
          URL.revokeObjectURL(url);
          toast.success(t('settings.exportReady'));
          return;
        }
        toast.info(t('settings.exportReadyBody', { chars: json.length }));
        return;
      }

      // Native: write JSON to documents dir, then hand to system share sheet.
      const uri = `${FileSystem.documentDirectory}user-data-export-${Date.now()}.json`;
      await FileSystem.writeAsStringAsync(uri, json, { encoding: FileSystem.EncodingType.UTF8 });
      if (await Sharing.isAvailableAsync()) {
        await Sharing.shareAsync(uri, {
          mimeType: 'application/json',
          dialogTitle: t('settings.exportShareTitle'),
          UTI: 'public.json',
        });
      } else {
        toast.info(t('settings.exportReadyBody', { chars: json.length }));
      }
    } catch (e) {
      toast.error(`${t('settings.exportFailed')}: ${(e as Error).message}`);
    } finally {
      setExporting(false);
    }
  };

  const del = useMutation({
    mutationFn: deleteMyAccount,
    onSuccess: () => {
      toast.success(t('settings.accountDeletedTitle'));
    },
    onError: (e) => toast.error(`${t('settings.deleteFailed')}: ${(e as Error).message}`),
  });

  const onDelete = () => {
    confirm({
      title: t('settings.deleteConfirm.title'),
      body: t('settings.deleteConfirm.body'),
      confirmLabel: t('settings.deleteConfirm.action'),
      cancelLabel: t('settings.deleteConfirm.cancel'),
      destructive: true,
      onConfirm: () =>
        new Promise<void>((resolve, reject) => {
          del.mutate(undefined, {
            onSuccess: () => resolve(),
            onError: (e) => reject(e),
          });
        }),
    });
  };

  return (
    <View className="mt-6">
      <Text className="font-display-semibold text-muted text-display-xs uppercase tracking-wide mb-2">
        {t('settings.account')}
      </Text>
      <View className="mb-3">
        <Button testID="account-export" variant="outline" onPress={onExport} loading={exporting}>
          {t('settings.exportData')}
        </Button>
      </View>

      {/* Advanced disclosure — keeps the destructive Delete account action out of */}
      {/* casual eyesight per P2-10 / audit feedback. Tap chevron to reveal. */}
      <Pressable
        testID="account-advanced-toggle"
        onPress={() => setAdvancedOpen((v) => !v)}
        accessibilityRole="button"
        accessibilityState={{ expanded: advancedOpen }}
        accessibilityLabel={t('settings.advanced')}
        className="flex-row items-center justify-between py-2 px-1 active:opacity-70"
      >
        <Text className="font-display-semibold text-body-md text-muted uppercase tracking-wide">
          {t('settings.advanced')}
        </Text>
        {advancedOpen ? (
          <ChevronDown size={16} color={colors.muted} />
        ) : (
          <ChevronRight size={16} color={colors.muted} />
        )}
      </Pressable>

      {advancedOpen ? (
        <View testID="account-advanced-panel" className="mt-1">
          <Button
            testID="account-delete"
            variant="outline-danger"
            onPress={onDelete}
            loading={del.isPending}
          >
            {t('settings.deleteAccount')}
          </Button>
        </View>
      ) : null}
    </View>
  );
}
