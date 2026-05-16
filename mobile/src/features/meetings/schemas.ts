import { z } from 'zod';

export const SlotsSchema = z
  .array(
    z.string().refine((iso) => !Number.isNaN(Date.parse(iso)) && Date.parse(iso) > Date.now(), {
      message: 'Slot must be a future ISO timestamp',
    })
  )
  .min(1)
  .max(3);

export const DurationSchema = z.number().int().min(15).max(240);

export const MeetingUrlSchema = z.preprocess(
  (v) => (typeof v === 'string' && v.trim() === '' ? undefined : v),
  z.string().url().startsWith('https://').optional()
);

export const FeedbackNoteSchema = z.string().max(1000).optional().or(z.literal(''));

export const RatingSchema = z.enum(['positive', 'neutral', 'negative']);
