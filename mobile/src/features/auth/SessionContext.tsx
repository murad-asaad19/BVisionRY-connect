import { createContext, useContext, ReactNode } from 'react';
import type { Session } from '@supabase/supabase-js';
import { useSession } from '~/features/auth/hooks/useSession';

type SessionContextValue = { session: Session | null; loading: boolean };

const SessionContext = createContext<SessionContextValue>({ session: null, loading: true });

export function SessionProvider({ children }: { children: ReactNode }) {
  const value = useSession();
  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>;
}

export const useAuthSession = () => useContext(SessionContext);
