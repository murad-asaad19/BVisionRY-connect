import { useTranslation } from 'react-i18next';
import type { IntroState } from '~/features/intros/services/intros.service';
import { Pill, type PillVariant } from '~/components/ui/Pill';

export type IntroBadgeAudience = 'recipient' | 'sender';

type DisplayState = IntroState | 'awaiting_response';

function effectiveState(
  state: IntroState,
  audience: IntroBadgeAudience,
  expiresAt: string | null | undefined
): DisplayState {
  // The expiry cron only flips `delivered → expired`. A declined intro past
  // its expires_at would otherwise stay 'declined' forever — and for the sender
  // we'd mask it as "awaiting_response" indefinitely. Short-circuit to
  // 'expired' for those two non-terminal pre-acceptance states only. Terminal
  // states (accepted / connected) and the already-expired state stay as-is even
  // when expires_at is in the past — an accepted intro doesn't "expire."
  if (
    expiresAt &&
    Date.parse(expiresAt) < Date.now() &&
    (state === 'delivered' || state === 'declined')
  ) {
    return 'expired';
  }
  // §12: sender never sees a Declined intro — show "Delivered, awaiting response"
  // until the intro auto-expires. After expiry, the branch above takes over.
  if (audience === 'sender' && state === 'declined') return 'awaiting_response';
  return state;
}

// Keys live under intros.badge.*; mapping is from the runtime DisplayState to the
// i18n leaf so the LABEL surface here stays the single source of truth for both
// the visible string and the testID slug.
const I18N_KEY: Record<DisplayState, string> = {
  delivered: 'intros.badge.delivered',
  accepted: 'intros.badge.accepted',
  declined: 'intros.badge.declined',
  expired: 'intros.badge.expired',
  connected: 'intros.badge.connected',
  awaiting_response: 'intros.badge.awaitingResponse',
};

const VARIANT: Record<DisplayState, PillVariant> = {
  delivered: 'default',
  accepted: 'success',
  declined: 'warning',
  expired: 'muted',
  connected: 'navy',
  awaiting_response: 'default',
};

type Props = {
  state: IntroState;
  audience?: IntroBadgeAudience;
  /** ISO timestamp of the intro's expiry. Required so the badge can override
   *  stale `declined`/`delivered` rows past their expiry window. Optional only
   *  to keep the unit-test surface backwards compatible; pass it in production. */
  expiresAt?: string | null;
};

export function IntroStateBadge({ state, audience = 'recipient', expiresAt }: Props) {
  const { t } = useTranslation();
  const effective = effectiveState(state, audience, expiresAt);
  return (
    <Pill variant={VARIANT[effective]} testID={`intro-state-badge-${effective}`}>
      {t(I18N_KEY[effective])}
    </Pill>
  );
}
