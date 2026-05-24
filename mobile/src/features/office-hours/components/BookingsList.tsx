import { useState } from 'react';
import { View, Text } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Calendar, Trash2 } from 'lucide-react-native';
import { useMyBookings } from '~/features/office-hours/hooks/useMyBookings';
import { useCancelBooking } from '~/features/office-hours/hooks/useCancelBooking';
import { AvatarCircle } from '~/components/ui/AvatarCircle';
import { QueryState } from '~/components/ui/QueryState';
import { EmptyState } from '~/components/ui/EmptyState';
import { Skeleton } from '~/components/ui/Skeleton';
import { IconButton } from '~/components/ui/IconButton';
import { useConfirm } from '~/components/ui/ConfirmDialog';
import { useToast } from '~/components/ui/Toast';
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
 * Skeleton for the bookings list. Mirrors the BookingRow geometry (avatar +
 * two-line text + trailing action) so the swap to real data doesn't reflow.
 */
function BookingsSkeleton({ count = 4 }: { count?: number }) {
  return (
    <View testID="bookings-list-loading">
      {Array.from({ length: count }).map((_, i) => (
        <View
          key={i}
          className={`bg-white border border-border rounded-[10px] p-card flex-row items-center gap-3 ${
            i === 0 ? '' : 'mt-2'
          }`}
        >
          <Skeleton w={38} h={38} radius={19} />
          <View className="flex-1">
            <Skeleton w="55%" h={12} />
            <View className="mt-1.5">
              <Skeleton w="80%" h={10} />
            </View>
          </View>
          <Skeleton w={32} h={32} radius={16} />
        </View>
      ))}
    </View>
  );
}

/**
 * Renders the caller's upcoming office-hours bookings with a cancel CTA.
 * Loading state is a skeleton list; empty state is the branded EmptyState.
 */
export function BookingsList() {
  const { t } = useTranslation();
  const query = useMyBookings();
  return (
    <QueryState
      query={query}
      loadingFallback={<BookingsSkeleton count={4} />}
      isEmpty={(rows) => rows.length === 0}
      emptyFallback={
        <EmptyState
          testID="bookings-empty"
          icon={Calendar}
          title={t('officeHours.bookings.emptyTitle')}
          body={t('officeHours.bookings.emptyBody')}
        />
      }
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
  const confirm = useConfirm();
  const toast = useToast();
  const cancel = useCancelBooking();
  const [busy, setBusy] = useState(false);

  const onCancel = async () => {
    if (busy) return;
    const ok = await confirm({
      title: t('officeHours.bookings.cancelConfirm'),
      body: t('officeHours.bookings.cancelConfirmBody'),
      confirmLabel: t('officeHours.bookings.cancel'),
      cancelLabel: t('common.cancel'),
      destructive: true,
    });
    if (!ok) return;
    setBusy(true);
    try {
      await cancel.mutateAsync({ slotId: row.slotId, hostId: row.hostId });
      toast.success(t('officeHours.bookings.cancelled'));
    } catch (e) {
      const message = e instanceof Error ? e.message : t('officeHours.bookings.cancelFailed');
      toast.error(message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <View
      testID={`booking-row-${row.slotId}`}
      className="bg-white border border-border rounded-[10px] p-card mb-2 flex-row items-center gap-3"
    >
      <AvatarCircle name={row.hostName} photoUrl={row.hostPhotoUrl} size={38} />
      <View className="flex-1 min-w-0">
        <Text className="font-display-bold text-display-sm text-navy" numberOfLines={1}>
          {row.hostName}
        </Text>
        <Text className="font-body text-body-sm text-muted mt-0.5" numberOfLines={1}>
          {formatRange(row.startsAt, row.endsAt)}
        </Text>
        {row.topic ? (
          <Text className="font-body text-body-sm text-body mt-1" numberOfLines={2}>
            {row.topic}
          </Text>
        ) : null}
      </View>
      <IconButton
        icon={Trash2}
        onPress={onCancel}
        disabled={busy}
        label={t('officeHours.bookings.cancel')}
        size="sm"
        variant="subtle"
        testID={`booking-cancel-${row.slotId}`}
      />
    </View>
  );
}
