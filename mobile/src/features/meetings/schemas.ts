import { z } from 'zod';

/** Future buffer enforced on every proposed slot: must be ≥5 minutes out. */
const FUTURE_BUFFER_MS = 5 * 60 * 1000;

export const SlotsSchema = z
  .array(
    z.string().refine(
      (iso) => {
        const t = Date.parse(iso);
        return !Number.isNaN(t) && t >= Date.now() + FUTURE_BUFFER_MS;
      },
      { message: 'Slot must be at least 5 minutes in the future' }
    )
  )
  .min(1)
  .max(3);

export const DurationSchema = z.number().int().min(15).max(240);

export const MeetingUrlSchema = z.preprocess(
  (v) => (typeof v === 'string' && v.trim() === '' ? undefined : v),
  z.string().url().startsWith('https://').optional()
);

/** Outcome enum for the post-meeting review surface (matches submit_meeting_review). */
export const OutcomeSchema = z.enum(['useful', 'not_useful', 'no_show']);
