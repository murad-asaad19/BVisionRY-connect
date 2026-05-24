import { create } from 'zustand';

type State = {
  activeId: string | null;
  setActive: (id: string | null) => void;
};

/**
 * Tracks which conversation is currently mounted on-screen.
 *
 * Realtime handlers read this via `useActiveConversationStore.getState()` to
 * suppress the `unread_count` bump for the chat the user is actively viewing
 * (the server's `mark_conversation_read` debounce will zero it shortly).
 * Reading via `getState()` from non-render contexts avoids forcing a
 * re-render on every channel handler invocation.
 */
export const useActiveConversationStore = create<State>((set) => ({
  activeId: null,
  setActive: (id) => set({ activeId: id }),
}));
