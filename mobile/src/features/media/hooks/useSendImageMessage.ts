import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '~/lib/supabase/client';
import { useAuthSession } from '~/features/auth/SessionContext';
import { pickImage } from '~/features/media/hooks/usePickImage';
import { uploadChatMedia } from '~/features/media/services/storage.service';

export function useSendImageMessage(conversationId: string) {
  const qc = useQueryClient();
  const { session } = useAuthSession();
  return useMutation({
    mutationFn: async () => {
      const userId = session?.user.id;
      if (!userId) throw new Error('not signed in');
      const picked = await pickImage();
      if (!picked) return null;

      // 1. Insert message row with kind=image, media_path=PLACEHOLDER
      // We need messageId before uploading. Insert then update.
      const placeholderPath = `pending/${Date.now()}.jpg`;
      const { data: msg, error: insertErr } = await supabase
        .from('messages')
        .insert({
          conversation_id: conversationId,
          sender_id: userId,
          kind: 'image',
          media_path: placeholderPath,
          media_size_bytes: picked.blob.size,
        })
        .select()
        .single();
      if (insertErr) throw new Error(insertErr.message);

      // 2. Upload to chat-media bucket using the real message id
      const path = await uploadChatMedia(conversationId, msg.id, picked.blob, 'jpg', 'image/jpeg');

      // 3. Patch message row with real path
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
