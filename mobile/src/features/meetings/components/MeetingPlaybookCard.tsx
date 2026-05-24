import { useState } from 'react';
import { View, Text, Pressable, ActivityIndicator } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Pill } from '~/components/ui/Pill';
import { Banner } from '~/components/ui/Banner';
import { useMeetingPlaybook } from '~/features/meetings/hooks/useMeetingPlaybook';

type Props = {
  meetingId: string;
  /** Other-attendee name — used for the section heading "About {name}". */
  targetName?: string | null;
};

/**
 * Convert an ISO timestamp into a coarse English-ish "n minutes/hours/days ago"
 * label. Keeps the implementation tiny — the playbook card only ever shows a
 * rough age and there's no existing date-utils module in this codebase.
 */
function formatAgo(iso: string, justNowLabel: string, minLabel: string, hrLabel: string, dayLabel: string): string {
  const ms = Date.now() - new Date(iso).getTime();
  const min = Math.round(ms / 60_000);
  if (min < 1) return justNowLabel;
  if (min < 60) return `${min}${minLabel}`;
  const hr = Math.round(min / 60);
  if (hr < 24) return `${hr}${hrLabel}`;
  const day = Math.round(hr / 24);
  return `${day}${dayLabel}`;
}

function SectionHeader({ children }: { children: string }) {
  return (
    <Text className="font-display-bold text-[11px] text-muted uppercase tracking-wide mt-3 mb-1.5">
      {children}
    </Text>
  );
}

function BulletList({ items, testID }: { items: string[]; testID?: string }) {
  return (
    <View className="gap-1.5" testID={testID}>
      {items.map((item, i) => (
        <View key={i} className="flex-row gap-2">
          <Text className="font-body text-[12px] text-muted">•</Text>
          <Text className="font-body text-[12px] text-body flex-1">{item}</Text>
        </View>
      ))}
    </View>
  );
}

function PillRow({ items, testID }: { items: string[]; testID?: string }) {
  return (
    <View className="flex-row flex-wrap gap-1.5" testID={testID}>
      {items.map((it, i) => (
        <Pill key={i} variant="default">
          {it}
        </Pill>
      ))}
    </View>
  );
}

/**
 * AI-generated meeting playbook card. Mounted inside `MeetingCard` when the
 * meeting is confirmed and starts within 24h. Manages its own loading +
 * error states; pulls data from `useMeetingPlaybook(meetingId)`.
 */
export function MeetingPlaybookCard({ meetingId, targetName }: Props) {
  const { t } = useTranslation();
  const { playbook, isLoading, isGenerating, error, isRateLimited, regenerate } =
    useMeetingPlaybook(meetingId);
  const [collapsed, setCollapsed] = useState<Record<string, boolean>>({});

  const toggle = (key: string) =>
    setCollapsed((prev) => ({ ...prev, [key]: !prev[key] }));

  // Initial load + no cached row + a generation in flight → full skeleton.
  const isInitialGenerating = !playbook && (isLoading || isGenerating);

  if (isInitialGenerating) {
    return (
      <View
        testID="meeting-playbook-card-loading"
        className="bg-white border border-border rounded-xl p-4 my-2 mx-2"
      >
        <Text className="font-display-bold text-[11px] text-muted uppercase tracking-wide mb-2">
          {t('meetings.playbook.title')}
        </Text>
        <View className="flex-row items-center gap-2">
          <ActivityIndicator color="#0f3460" />
          <Text className="font-body text-[12px] text-muted">
            {t('meetings.playbook.generating')}
          </Text>
        </View>
        {/* Skeleton rows */}
        <View className="mt-3 gap-2">
          <View className="h-3 w-3/4 bg-slate-200 rounded" />
          <View className="h-3 w-1/2 bg-slate-200 rounded" />
          <View className="h-3 w-2/3 bg-slate-200 rounded" />
        </View>
      </View>
    );
  }

  if (error && !playbook) {
    return (
      <View
        testID="meeting-playbook-card-error"
        className="my-2 mx-2"
      >
        <Pressable
          onPress={() => regenerate()}
          accessibilityRole="button"
          testID="meeting-playbook-retry"
        >
          <Banner variant="warning" title={t('meetings.playbook.errorBanner')}>
            {t('meetings.playbook.retry')}
          </Banner>
        </Pressable>
      </View>
    );
  }

  if (!playbook) {
    // No data, no error, nothing in flight. Render nothing.
    return null;
  }

  const ago = formatAgo(
    playbook.generatedAt,
    t('meetings.playbook.justNow'),
    t('meetings.playbook.minutesShort'),
    t('meetings.playbook.hoursShort'),
    t('meetings.playbook.daysShort')
  );

  const summaryTitle = targetName
    ? t('meetings.playbook.section.summary', { name: targetName })
    : t('meetings.playbook.section.summaryNoName');

  return (
    <View
      testID="meeting-playbook-card"
      className="bg-white border border-gold rounded-xl p-4 my-2 mx-2"
    >
      <View className="flex-row items-center justify-between mb-1">
        <Text className="font-display-bold text-[12px] text-navy">
          {t('meetings.playbook.title')}
        </Text>
        <Pressable
          testID="meeting-playbook-regenerate"
          onPress={() => regenerate()}
          disabled={isRateLimited || isGenerating}
          accessibilityRole="button"
          accessibilityState={{ disabled: isRateLimited || isGenerating }}
          className={`px-2 py-1 rounded-md ${
            isRateLimited || isGenerating ? 'bg-slate-100' : 'bg-white border border-border'
          }`}
        >
          {isGenerating ? (
            <ActivityIndicator color="#0f3460" />
          ) : (
            <Text
              className={`font-display-semibold text-[10px] ${
                isRateLimited ? 'text-muted' : 'text-navy'
              }`}
            >
              {t('meetings.playbook.regenerate')}
            </Text>
          )}
        </Pressable>
      </View>
      <Text
        className="font-body text-[10px] text-muted mb-1"
        testID="meeting-playbook-generated-at"
      >
        {t('meetings.playbook.generatedAt', { ago })}
      </Text>
      {isRateLimited && (
        <Text className="font-body text-[10px] text-muted mb-1">
          {t('meetings.playbook.regenerateRateLimited')}
        </Text>
      )}

      {/* Summary */}
      <Pressable
        onPress={() => toggle('summary')}
        accessibilityRole="button"
      >
        <SectionHeader>{summaryTitle}</SectionHeader>
      </Pressable>
      {!collapsed.summary && (
        <Text
          testID="meeting-playbook-summary"
          className="font-body text-[12px] text-body"
        >
          {playbook.summary}
        </Text>
      )}

      {/* Shared interests */}
      {playbook.sharedInterests.length > 0 && (
        <>
          <Pressable
            onPress={() => toggle('shared')}
            accessibilityRole="button"
          >
            <SectionHeader>
              {t('meetings.playbook.section.sharedInterests')}
            </SectionHeader>
          </Pressable>
          {!collapsed.shared && (
            <PillRow
              items={playbook.sharedInterests}
              testID="meeting-playbook-shared-interests"
            />
          )}
        </>
      )}

      {/* Conversation starters */}
      {playbook.conversationStarters.length > 0 && (
        <>
          <Pressable
            onPress={() => toggle('starters')}
            accessibilityRole="button"
          >
            <SectionHeader>
              {t('meetings.playbook.section.conversationStarters')}
            </SectionHeader>
          </Pressable>
          {!collapsed.starters && (
            <BulletList
              items={playbook.conversationStarters}
              testID="meeting-playbook-conversation-starters"
            />
          )}
        </>
      )}

      {/* Do */}
      {playbook.doNotes.length > 0 && (
        <>
          <Pressable onPress={() => toggle('do')} accessibilityRole="button">
            <SectionHeader>{t('meetings.playbook.section.do')}</SectionHeader>
          </Pressable>
          {!collapsed.do && (
            <BulletList items={playbook.doNotes} testID="meeting-playbook-do" />
          )}
        </>
      )}

      {/* Don't */}
      {playbook.dontNotes.length > 0 && (
        <>
          <Pressable onPress={() => toggle('dont')} accessibilityRole="button">
            <SectionHeader>{t('meetings.playbook.section.dont')}</SectionHeader>
          </Pressable>
          {!collapsed.dont && (
            <BulletList items={playbook.dontNotes} testID="meeting-playbook-dont" />
          )}
        </>
      )}
    </View>
  );
}
