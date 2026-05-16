import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { supabase } from '~/lib/supabase/client';
import type { MeetingProposalRow } from '~/features/meetings/services/meetings.service';

/**
 * Subscribes to INSERT and UPDATE events on meeting_proposals filtered by
 * conversation_id. Pushes incoming rows into the ['meeting-proposals',
 * conversationId] cache (replace by id, append if new).
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
          qc.invalidateQueries({ queryKey: ['pending-feedback', conversationId] });
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [conversationId, qc]);
}
