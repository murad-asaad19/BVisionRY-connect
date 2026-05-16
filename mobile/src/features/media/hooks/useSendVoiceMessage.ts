import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '~/lib/supabase/client';
import { useAuthSession } from '~/features/auth/SessionContext';
import { uploadChatMedia } from '~/features/media/services/storage.service';

export function useSendVoiceMessage(conversationId: string) {
  const qc = useQueryClient();
  const { session } = useAuthSession();
  return useMutation({
    mutationFn: async (recording: { uri: string; durationMs: number }) => {
      const userId = session?.user.id;
      if (!userId) throw new Error('not signed in');
      const blob = await fetch(recording.uri).then((r) => r.blob());
      const placeholderPath = `pending/${Date.now()}.m4a`;
      const { data: msg, error: insertErr } = await supabase
        .from('messages')
        .insert({
          conversation_id: conversationId,
          sender_id: userId,
          kind: 'voice',
          media_path: placeholderPath,
          media_duration_ms: Math.round(recording.durationMs),
          media_size_bytes: blob.size,
        })
        .select()
        .single();
      if (insertErr) throw new Error(insertErr.message);
      const path = await uploadChatMedia(conversationId, msg.id, blob, 'm4a', 'audio/m4a');
      const { error: updErr } = await supabase
        .from('messages')
        .update({ media_path: path })
        .eq('id', msg.id);
      if (updErr) throw new Error(updErr.message);
      return msg.id;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['messages', conversationId] });
      qc.invalidateQueries({ queryKey: ['conversations'] });
    },
  });
}
