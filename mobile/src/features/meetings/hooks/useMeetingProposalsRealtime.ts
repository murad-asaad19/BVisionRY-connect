import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { supabase } from '~/lib/supabase/client';
import type { MeetingProposalRow } from '~/features/meetings/services/meetings.service';

/**
 * Subscribes to INSERT/UPDATE/DELETE events on meeting_proposals filtered by
 * conversation_id. On INSERT/UPDATE the row is upserted into the
 * ['meeting-proposals', conversationId] cache; on DELETE the id is dropped.
 */
export function useMeetingProposalsRealtime(conversationId: string) {
  const qc = useQueryClient();

  useEffect(() => {
    if (!conversationId) return;

    const channel = supabase
      .channel(`meeting-proposals:${conversationId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'meeting_proposals',
          filter: `conversation_id=eq.${conversationId}`,
        },
        (payload) => {
          if (payload.eventType === 'DELETE') {
            const oldRow = payload.old as { id?: string } | null;
            const id = oldRow?.id;
            if (!id) return;
            qc.setQueryData<MeetingProposalRow[]>(['meeting-proposals', conversationId], (prev) => {
              if (!prev) return prev;
              return prev.filter((p) => p.id !== id);
            });
            qc.invalidateQueries({ queryKey: ['pending-meeting-reviews'] });
            return;
          }

          const row = payload.new as MeetingProposalRow | null;
          if (!row) return;
          qc.setQueryData<MeetingProposalRow[]>(['meeting-proposals', conversationId], (prev) => {
            if (!prev) return [row];
            const idx = prev.findIndex((p) => p.id === row.id);
            if (idx === -1) return [row, ...prev];
            const next = [...prev];
            next[idx] = row;
            return next;
          });
          qc.invalidateQueries({ queryKey: ['pending-meeting-reviews'] });
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [conversationId, qc]);
}
