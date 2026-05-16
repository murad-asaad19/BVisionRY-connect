import { Pressable, Text, Platform, Alert } from 'react-native';
import { File, Paths } from 'expo-file-system';
import * as Sharing from 'expo-sharing';
import { useTranslation } from 'react-i18next';
import { generateICS } from '~/features/meetings/services/ics.service';

type Props = {
  meetingId: string;
  startIso: string;
  durationMinutes: number;
  meetingUrl: string | null;
  summary: string;
};

export function ICSDownloadButton({
  meetingId,
  startIso,
  durationMinutes,
  meetingUrl,
  summary,
}: Props) {
  const { t } = useTranslation();
  const label = t('meetings.addToCalendar');
  const onPress = async () => {
    const ics = generateICS({
      meetingId,
      startIso,
      durationMinutes,
      summary,
      url: meetingUrl,
    });

    if (Platform.OS === 'web') {
      try {
        const blob = new Blob([ics], { type: 'text/calendar' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `meeting-${meetingId}.ics`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      } catch (e) {
        Alert.alert('Download failed', (e as Error).message);
      }
      return;
    }

    try {
      const file = new File(Paths.document, `meeting-${meetingId}.ics`);
      if (file.exists) file.delete();
      file.create();
      file.write(ics);

      const available = await Sharing.isAvailableAsync();
      if (!available) {
        Alert.alert('Saved', `ICS saved to ${file.uri}`);
        return;
      }
      await Sharing.shareAsync(file.uri, {
        mimeType: 'text/calendar',
        UTI: 'public.calendar-event',
        dialogTitle: label,
      });
    } catch (e) {
      Alert.alert('Save failed', (e as Error).message);
    }
  };

  return (
    <Pressable
      testID="meeting-ics-download"
      onPress={onPress}
      accessibilityRole="button"
      accessibilityLabel={label}
      className="bg-white border border-border rounded-lg px-3 py-2 mt-2 self-start"
    >
      <Text className="text-body text-sm">{label}</Text>
    </Pressable>
  );
}
