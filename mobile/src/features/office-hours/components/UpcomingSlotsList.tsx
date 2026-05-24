import { useMemo } from 'react';
import { View, Text, Pressable } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Calendar } from 'lucide-react-native';
import { QueryState } from '~/components/ui/QueryState';
import { EmptyState } from '~/components/ui/EmptyState';
import { Skeleton } from '~/components/ui/Skeleton';
import { useUpcomingSlots } from '~/features/office-hours/hooks/useUpcomingSlots';
import type { UpcomingSlot } from '~/features/office-hours/services/officeHours.service';

type Props = {
  hostId: string;
  onPickSlot: (slot: UpcomingSlot) => void;
  testID?: string;
};

function dayKeyFor(iso: string): string {
  try {
    return new Date(iso).toLocaleDateString(undefined, {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
    });
  } catch {
    return iso.slice(0, 10);
  }
}

function timeFor(iso: string): string {
  try {
    return new Date(iso).toLocaleTimeString(undefined, {
      hour: 'numeric',
      minute: '2-digit',
    });
  } catch {
    return iso.slice(11, 16);
  }
}

/**
 * Skeleton matched to the real layout (eyebrow + a row of pills) so the slot
 * grid doesn't visibly reflow when data arrives.
 */
function SlotsSkeleton() {
  return (
    <View testID="upcoming-slots-loading">
      {Array.from({ length: 2 }).map((_, day) => (
        <View key={day} className={day === 0 ? '' : 'mt-3'}>
          <Skeleton w={120} h={10} />
          <View className="flex-row flex-wrap gap-1.5 mt-2">
            {Array.from({ length: 4 }).map((__, i) => (
              <Skeleton key={i} w={64} h={26} radius={14} />
            ))}
          </View>
        </View>
      ))}
    </View>
  );
}

/**
 * Groups open slots by day and renders tappable time pills. The parent gates
 * the surrounding section, but the loading/empty surfaces live here so callers
 * don't have to re-implement the branded treatments.
 */
export function UpcomingSlotsList({ hostId, onPickSlot, testID }: Props) {
  const { t } = useTranslation();
  const query = useUpcomingSlots(hostId);

  return (
    <QueryState
      query={query}
      loadingFallback={<SlotsSkeleton />}
      isEmpty={(rows) => rows.length === 0}
      emptyFallback={
        <EmptyState
          testID="upcoming-slots-empty"
          icon={Calendar}
          title={t('officeHours.bookings.slotsEmptyTitle')}
          body={t('officeHours.bookings.slotsEmptyBody')}
        />
      }
    >
      {(rows) => <SlotsContent rows={rows} onPickSlot={onPickSlot} testID={testID} />}
    </QueryState>
  );
}

function SlotsContent({
  rows,
  onPickSlot,
  testID,
}: {
  rows: UpcomingSlot[];
  onPickSlot: (slot: UpcomingSlot) => void;
  testID?: string;
}) {
  const grouped = useMemo(() => {
    const map = new Map<string, UpcomingSlot[]>();
    rows.forEach((s) => {
      const k = dayKeyFor(s.startsAt);
      const list = map.get(k) ?? [];
      list.push(s);
      map.set(k, list);
    });
    return Array.from(map.entries());
  }, [rows]);

  return (
    <View testID={testID ?? 'upcoming-slots-list'}>
      {grouped.map(([day, slots]) => (
        <View key={day} className="mb-2">
          <Text className="font-display-bold text-body-xs text-muted uppercase tracking-wide mb-1">
            {day}
          </Text>
          <View className="flex-row flex-wrap gap-1.5">
            {slots.map((s) => (
              <Pressable
                key={s.id}
                testID={`upcoming-slot-${s.id}`}
                onPress={() => onPickSlot(s)}
                accessibilityRole="button"
                accessibilityLabel={`${day} ${timeFor(s.startsAt)}`}
                className="px-2.5 py-1.5 rounded-full bg-gold-pale border border-gold"
              >
                <Text className="font-display-bold text-body-sm text-navy">
                  {timeFor(s.startsAt)}
                </Text>
              </Pressable>
            ))}
          </View>
        </View>
      ))}
    </View>
  );
}
