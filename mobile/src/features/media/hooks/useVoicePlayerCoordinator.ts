import { useEffect, useRef } from 'react';

// Module-scope active-player coordinator: ensures only one VoiceMessageBubble
// plays at a time. Each bubble registers a `pause()` callback under its own
// id; calling `setActive(id)` invokes the previous active id's `pause()` then
// records the new id. On unmount, the bubble unregisters itself.

type PauseFn = () => void;

const registry = new Map<string, PauseFn>();
let activeId: string | null = null;

function setActive(id: string) {
  if (activeId && activeId !== id) {
    const prev = registry.get(activeId);
    prev?.();
  }
  activeId = id;
}

function clearActive(id: string) {
  if (activeId === id) activeId = null;
}

/**
 * Returns helpers a VoiceMessageBubble can call:
 *   * `notifyPlay()` — call right before `player.play()`. Pauses any other
 *     active bubble and marks this one active.
 *   * `notifyPause()` — call right after `player.pause()` so we don't try to
 *     pause an already-paused player on the next bubble's play.
 *
 * The bubble must pass a stable `id` (e.g. mediaPath). The `pause` callback
 * is the live ref to the player's pause method; we re-register on each render
 * to keep the closure fresh against the latest player instance.
 */
export function useVoicePlayerCoordinator(id: string, pause: PauseFn) {
  const pauseRef = useRef(pause);
  pauseRef.current = pause;

  useEffect(() => {
    const wrapper: PauseFn = () => pauseRef.current();
    registry.set(id, wrapper);
    return () => {
      registry.delete(id);
      clearActive(id);
    };
  }, [id]);

  return {
    notifyPlay: () => setActive(id),
    notifyPause: () => clearActive(id),
  };
}
