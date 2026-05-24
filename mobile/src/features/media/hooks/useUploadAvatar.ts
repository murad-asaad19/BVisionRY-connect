import { useMutation, useQueryClient } from '@tanstack/react-query';
import { File } from 'expo-file-system';
import { useAuthSession } from '~/features/auth/SessionContext';
import { pickImage } from '~/features/media/hooks/usePickImage';
import { uploadAvatar } from '~/features/media/services/storage.service';
import { supabase } from '~/lib/supabase/client';

export function useUploadAvatar() {
  const qc = useQueryClient();
  const { session } = useAuthSession();
  return useMutation({
    mutationFn: async (): Promise<string | null> => {
      const userId = session?.user.id;
      if (!userId) throw new Error('not signed in');
      const picked = await pickImage({ aspect: [1, 1] });
      if (!picked) return null;
      try {
        const publicUrl = await uploadAvatar(userId, picked.blob, picked.ext);
        const { error } = await supabase
          .from('profiles')
          .update({ photo_url: publicUrl })
          .eq('id', userId);
        if (error) throw new Error(error.message);
        return publicUrl;
      } finally {
        try {
          const tmp = new File(picked.uri);
          if (tmp.exists) tmp.delete();
        } catch {
          // Non-fatal.
        }
      }
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['profile'] });
      qc.invalidateQueries({ queryKey: ['profile-by-id'] });
      qc.invalidateQueries({ queryKey: ['profile-by-handle'] });
    },
  });
}
