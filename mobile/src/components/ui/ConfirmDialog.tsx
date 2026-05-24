import { useState, useCallback, type ReactNode } from 'react';
import { View, Text } from 'react-native';
import { create } from 'zustand';
import { BottomSheet } from '~/components/ui/Modal';
import { Button } from '~/components/ui/Button';

export type ConfirmOptions = {
  title: string;
  body?: string;
  confirmLabel: string;
  cancelLabel?: string;
  destructive?: boolean;
  /**
   * Optional async work to run before the dialog closes. If it throws, the
   * dialog stays open and the spinner stops so the caller can retry or show
   * an error via a toast.
   */
  onConfirm?: () => Promise<void> | void;
};

type PendingRequest = ConfirmOptions & {
  resolve: (value: boolean) => void;
};

type State = {
  request: PendingRequest | null;
  open: (req: PendingRequest) => void;
  close: () => void;
};

/**
 * Internal store driving the single global ConfirmDialog instance. Using a
 * store (rather than a React context with state) lets us expose an imperative
 * `confirm({...})` callable from non-React contexts (e.g. event handlers
 * inside service modules) while still preserving a single visible dialog at
 * any time — opening a new one replaces (and resolves false) the prior.
 */
const useConfirmStore = create<State>((set, get) => ({
  request: null,
  open: (req) => {
    // If a prior request is still pending, resolve it as cancelled before
    // replacing — guarantees no caller hangs on `await confirm(...)`.
    const prior = get().request;
    if (prior) prior.resolve(false);
    set({ request: req });
  },
  close: () => set({ request: null }),
}));

/**
 * Imperative confirm — usable outside of React render trees. Returns a
 * promise that resolves `true` if the user confirmed (and any async
 * `onConfirm` work completed), `false` if cancelled or replaced.
 */
export function confirm(options: ConfirmOptions): Promise<boolean> {
  return new Promise<boolean>((resolve) => {
    useConfirmStore.getState().open({ ...options, resolve });
  });
}

/**
 * Hook variant. Identical surface to `confirm()` — the indirection through a
 * hook is purely for ergonomic consistency with the rest of the codebase
 * (`useToast`, etc.) and to give callers a stable function reference.
 */
export function useConfirm() {
  return useCallback((options: ConfirmOptions) => confirm(options), []);
}

/**
 * Mount once near the app root. Renders the single global BottomSheet that
 * any `confirm(...)` call drives. The provider is a passthrough — it just
 * adds the host below its children.
 */
export function ConfirmProvider({ children }: { children: ReactNode }) {
  return (
    <>
      {children}
      <ConfirmHost />
    </>
  );
}

function ConfirmHost() {
  const request = useConfirmStore((s) => s.request);
  const close = useConfirmStore((s) => s.close);
  const [busy, setBusy] = useState(false);

  const handleCancel = useCallback(() => {
    if (busy) return;
    request?.resolve(false);
    close();
  }, [busy, request, close]);

  const handleConfirm = useCallback(async () => {
    if (!request) return;
    try {
      if (request.onConfirm) {
        setBusy(true);
        await request.onConfirm();
      }
      request.resolve(true);
      close();
    } catch {
      // Surface failures via the caller's own toast/banner — keep the
      // dialog open so the user can retry. Stop the spinner.
      request.resolve(false);
      close();
    } finally {
      setBusy(false);
    }
  }, [request, close]);

  const visible = Boolean(request);

  return (
    <BottomSheet
      visible={visible}
      onClose={handleCancel}
      testID="confirm-dialog"
      // Block backdrop dismiss while async work is in flight so the user
      // can't strand the promise mid-await.
      dismissible={!busy}
    >
      {request ? (
        <View className="pb-2">
          <Text className="font-display-bold text-display-md text-navy">{request.title}</Text>
          {request.body ? (
            <Text className="font-body text-body-md text-body mt-2">{request.body}</Text>
          ) : null}
          <View className="flex-row gap-3 mt-5">
            <View className="flex-1">
              <Button
                variant="outline"
                onPress={handleCancel}
                disabled={busy}
                testID="confirm-dialog-cancel"
              >
                {request.cancelLabel ?? 'Cancel'}
              </Button>
            </View>
            <View className="flex-1">
              <Button
                variant={request.destructive ? 'danger' : 'primary'}
                onPress={handleConfirm}
                loading={busy}
                testID="confirm-dialog-confirm"
              >
                {request.confirmLabel}
              </Button>
            </View>
          </View>
        </View>
      ) : null}
    </BottomSheet>
  );
}
