import { createContext, useContext, useMemo, ReactNode } from 'react';
import type { Session } from '@supabase/supabase-js';
import { useSession } from '~/features/auth/hooks/useSession';

type SessionContextValue = { session: Session | null; loading: boolean };

const SessionContext = createContext<SessionContextValue>({ session: null, loading: true });

export function SessionProvider({ children }: { children: ReactNode }) {
  const { session, loading } = useSession();
  // Memoize so consumers re-render only when session identity or loading
  // actually changes — otherwise a parent re-render rebuilds the object
  // every commit and forces the whole tree.
  const value = useMemo<SessionContextValue>(() => ({ session, loading }), [session, loading]);
  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>;
}

export const useAuthSession = () => useContext(SessionContext);
