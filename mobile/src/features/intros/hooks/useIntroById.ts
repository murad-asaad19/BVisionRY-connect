import { useQuery } from '@tanstack/react-query';
import { fetchIntroById } from '~/features/intros/services/intros.service';

// RFC 4122 — guard against unparseable path params (e.g. `[id]` empty string).
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function useIntroById(id: string) {
  const isValid = UUID_RE.test(id);
  return useQuery({
    queryKey: ['intros', 'by-id', id],
    queryFn: () => fetchIntroById(id),
    enabled: isValid,
    staleTime: 30_000,
  });
}
