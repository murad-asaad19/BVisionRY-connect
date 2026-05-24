import { useState } from 'react';
import { View, Text, Pressable, Alert } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useMyBookings } from '~/features/office-hours/hooks/useMyBookings';
import { useCancelBooking } from '~/features/office-hours/hooks/useCancelBooking';
import { AvatarCircle } from '~/components/ui/AvatarCircle';
import { QueryState } from '~/components/ui/QueryState';
import type { MyBooking } from '~/features/office-hours/services/officeHours.service';

function formatRange(start: string, end: string): string {
  try {
    const s = new Date(start);
    const e = new Date(end);
    const date = s.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' });
    const t1 = s.toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' });
    const t2 = e.toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' });
    return `${date} · ${t1} – ${t2}`;
  } catch {
    return `${start} – ${end}`;
  }
}

/**
 * Renders the caller's upcoming office-hours bookings with a cancel CTA.
 */
export function BookingsList() {
  const { t } = useTranslation();
  const query = useMyBookings();
  return (
    <QueryState
      query={query}
      isEmpty={(rows) => rows.length === 0}
      emptyText={t('officeHours.bookings.empty')}
    >
      {(rows) => (
        <View testID="bookings-list">
          {rows.map((row) => (
            <BookingRow key={row.slotId} row={row} />
          ))}
        </View>
      )}
    </QueryState>
  );
}

function BookingRow({ row }: { row: MyBooking }) {
  const { t } = useTranslation();
  const cancel = useCancelBooking();
  const [busy, setBusy] = useState(false);

  const confirm = () => {
    if (busy) return;
    Alert.alert(t('officeHours.bookings.cancelConfirm'), undefined, [
      { text: t('common.cancel'), style: 'cancel' },
      {
        text: t('officeHours.bookings.cancel'),
        style: 'destructive',
        onPress: async () => {
          setBusy(true);
          try {
            await cancel.mutateAsync({ slotId: row.slotId, hostId: row.hostId });
          } finally {
            setBusy(false);
          }
        },
      },
    ]);
  };

  return (
    <View
      testID={`booking-row-${row.slotId}`}
      className="bg-white border border-border rounded-[10px] p-3 mb-2 flex-row items-center gap-3"
    >
      <AvatarCircle name={row.hostName} photoUrl={row.hostPhotoUrl} size={38} />
      <View className="flex-1 min-w-0">
        <Text className="font-display-bold text-[13px] text-navy" numberOfLines={1}>
          {row.hostName}
        </Text>
        <Text className="text-[11px] text-muted mt-0.5" numberOfLines={1}>
          {formatRange(row.startsAt, row.endsAt)}
        </Text>
        {row.topic ? (
          <Text className="text-[11px] text-body font-body mt-1" numberOfLines={2}>
            {row.topic}
          </Text>
        ) : null}
      </View>
      <Pressable
        testID={`booking-cancel-${row.slotId}`}
        accessibilityRole="button"
        accessibilityLabel={t('officeHours.bookings.cancel')}
        onPress={confirm}
        disabled={busy}
        className="px-2.5 py-1.5 rounded-md bg-white border border-border"
      >
        <Text className="font-display-bold text-[11px] text-danger-text">
          {t('officeHours.bookings.cancel')}
        </Text>
      </Pressable>
    </View>
  );
}
