import { useQuery } from '@tanstack/react-query';
import { getChatMediaSignedUrl } from '~/features/media/services/storage.service';

// Supabase signed URLs default to 1h; cache them for 45m to leave a safety
// margin. ImageMessageBubble + VoiceMessageBubble share this hook so we don't
// fire one fetch per bubble per render.
const STALE_MS = 45 * 60 * 1000;

export function useSignedUrl(mediaPath: string | null | undefined) {
  return useQuery({
    queryKey: ['chat-media-signed-url', mediaPath],
    queryFn: () => {
      if (!mediaPath) throw new Error('mediaPath required');
      return getChatMediaSignedUrl(mediaPath);
    },
    enabled: !!mediaPath,
    staleTime: STALE_MS,
    gcTime: STALE_MS,
  });
}
