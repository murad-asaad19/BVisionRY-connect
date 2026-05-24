import { useMemo } from 'react';
import { View, Text, Pressable } from 'react-native';
import { useTranslation } from 'react-i18next';
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
 * Groups open slots by day and renders tappable time pills. Renders nothing
 * (caller-decided) when the list is empty — the parent gates the section.
 */
export function UpcomingSlotsList({ hostId, onPickSlot, testID }: Props) {
  const { t } = useTranslation();
  const query = useUpcomingSlots(hostId);

  const grouped = useMemo(() => {
    const map = new Map<string, UpcomingSlot[]>();
    (query.data ?? []).forEach((s) => {
      const k = dayKeyFor(s.startsAt);
      const list = map.get(k) ?? [];
      list.push(s);
      map.set(k, list);
    });
    return Array.from(map.entries());
  }, [query.data]);

  if (query.isLoading) {
    return (
      <View testID={testID ?? 'upcoming-slots-loading'} className="py-2">
        <Text className="font-body text-[11px] text-muted">…</Text>
      </View>
    );
  }
  if (!query.data || query.data.length === 0) {
    return (
      <View testID={testID ?? 'upcoming-slots-empty'}>
        <Text className="font-body text-[11px] text-muted">
          {t('officeHours.profile.noSlots')}
        </Text>
      </View>
    );
  }

  return (
    <View testID={testID ?? 'upcoming-slots-list'}>
      {grouped.map(([day, slots]) => (
        <View key={day} className="mb-2">
          <Text className="font-display-bold text-[10px] text-muted uppercase tracking-wide mb-1">
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
                <Text className="font-display-bold text-[11px] text-navy">
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
