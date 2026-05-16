import type { IntroState } from '~/features/intros/services/intros.service';
import { Pill, type PillVariant } from '~/components/ui/Pill';

export type IntroBadgeAudience = 'recipient' | 'sender';

type DisplayState = IntroState | 'awaiting_response';

function effectiveState(state: IntroState, audience: IntroBadgeAudience): DisplayState {
  // §12: sender never sees a Declined intro — show "Delivered, awaiting response"
  // until the intro auto-expires. After expiry, fall through to Expired.
  if (audience === 'sender' && state === 'declined') return 'awaiting_response';
  return state;
}

const LABEL: Record<DisplayState, string> = {
  delivered: 'Pending',
  accepted: 'Accepted',
  declined: 'Declined',
  expired: 'Expired',
  connected: 'Connected',
  awaiting_response: 'Delivered, awaiting response',
};

const VARIANT: Record<DisplayState, PillVariant> = {
  delivered: 'default',
  accepted: 'success',
  declined: 'warning',
  expired: 'muted',
  connected: 'navy',
  awaiting_response: 'default',
};

type Props = { state: IntroState; audience?: IntroBadgeAudience };

export function IntroStateBadge({ state, audience = 'recipient' }: Props) {
  const effective = effectiveState(state, audience);
  return (
    <Pill variant={VARIANT[effective]} testID={`intro-state-badge-${effective}`}>
      {LABEL[effective]}
    </Pill>
  );
}
