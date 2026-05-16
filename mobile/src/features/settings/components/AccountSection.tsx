import { useState } from 'react';
import { View, Text, Alert } from 'react-native';
import { useMutation } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
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
      // On web, trigger a file download; on native, surface size via alert
      if (typeof window !== 'undefined' && 'Blob' in window && typeof document !== 'undefined') {
        const blob = new Blob([json], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'my-data.json';
        a.click();
        URL.revokeObjectURL(url);
      } else {
        Alert.alert('Export ready', 'Your data is ready (length: ' + json.length + ' chars).');
      }
    } catch (e) {
      Alert.alert('Export failed', (e as Error).message);
    } finally {
      setExporting(false);
    }
  };

  const del = useMutation({
    mutationFn: deleteMyAccount,
    onError: (e) => Alert.alert('Delete failed', (e as Error).message),
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
          Alert.alert('Delete account?', 'This permanently removes your profile and data.', [
            { text: 'Cancel', style: 'cancel' },
            { text: 'Delete', style: 'destructive', onPress: () => del.mutate() },
          ])
        }
      >
        {t('settings.deleteAccount')}
      </Button>
    </View>
  );
}
