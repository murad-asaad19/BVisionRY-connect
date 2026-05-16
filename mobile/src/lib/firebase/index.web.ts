// Web build no-op. Firebase native modules don't run on web.
export async function initFirebase(): Promise<void> {
  // intentionally empty
}

export async function getFcmToken(): Promise<string | null> {
  return null;
}

export function onForegroundMessage(_handler: unknown): () => void {
  return () => {};
}
