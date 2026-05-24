import { useState } from 'react';
import { View, Text, Alert, Platform } from 'react-native';
import { useMutation } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import * as FileSystem from 'expo-file-system';
import * as Sharing from 'expo-sharing';
import { deleteMyAccount, exportMyData } from '~/features/settings/services/settings.service';
import { Button } from '~/components/ui/Button';

export function AccountSection() {
  const { t } = useTranslation();
  const [exporting, setExporting] = useState(false);

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
          return;
        }
        Alert.alert(t('settings.exportReady'), t('settings.exportReadyBody', { chars: json.length }));
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
        Alert.alert(t('settings.exportReady'), t('settings.exportReadyBody', { chars: json.length }));
      }
    } catch (e) {
      Alert.alert(t('settings.exportFailed'), (e as Error).message);
    } finally {
      setExporting(false);
    }
  };

  const del = useMutation({
    mutationFn: deleteMyAccount,
    onSuccess: () => {
      Alert.alert(t('settings.accountDeletedTitle'), t('settings.accountDeletedBody'));
    },
    onError: (e) => Alert.alert(t('settings.deleteFailed'), (e as Error).message),
  });

  return (
    <View className="mt-6">
      <Text className="font-display-semibold text-muted text-xs uppercase tracking-wide mb-2">
        {t('settings.account')}
      </Text>
      <View className="mb-3">
        <Button testID="account-export" variant="outline" onPress={onExport} loading={exporting}>
          {t('settings.exportData')}
        </Button>
      </View>
      <Button
        testID="account-delete"
        variant="danger"
        onPress={() =>
          Alert.alert(t('settings.deleteConfirm.title'), t('settings.deleteConfirm.body'), [
            { text: t('settings.deleteConfirm.cancel'), style: 'cancel' },
            {
              text: t('settings.deleteConfirm.action'),
              style: 'destructive',
              onPress: () => del.mutate(),
            },
          ])
        }
      >
        {t('settings.deleteAccount')}
      </Button>
    </View>
  );
}
