import { Pressable, Text, View, Platform } from 'react-native';
import { File, Paths } from 'expo-file-system';
import * as Sharing from 'expo-sharing';
import { useTranslation } from 'react-i18next';
import { Calendar } from 'lucide-react-native';
import { useToast } from '~/components/ui/Toast';
import { colors } from '~/theme/colors';
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
  const toast = useToast();
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
        toast.error((e as Error).message || t('meetings.icsDownloadFailed'));
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
        toast.success(t('meetings.icsSavedTo', { path: file.uri }));
        return;
      }
      await Sharing.shareAsync(file.uri, {
        mimeType: 'text/calendar',
        UTI: 'public.calendar-event',
        dialogTitle: label,
      });
    } catch (e) {
      toast.error((e as Error).message || t('meetings.icsDownloadFailed'));
    }
  };

  return (
    <Pressable
      testID="meeting-ics-download"
      onPress={onPress}
      accessibilityRole="button"
      accessibilityLabel={label}
      className="bg-white border border-border rounded-lg px-card py-2 mt-2 self-start flex-row items-center gap-2"
    >
      <View>
        <Calendar size={14} color={colors.navy} />
      </View>
      <Text className="font-display-semibold text-body-md text-body">{label}</Text>
    </Pressable>
  );
}
