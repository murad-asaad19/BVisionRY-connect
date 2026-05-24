import { z } from 'zod';

/**
 * Zod schemas mirroring the constraints in
 * supabase/migrations/20260608030000_office_hours.sql. Keep these in
 * lockstep with the migration — the DB is the source of truth and these
 * schemas exist for inline form validation only.
 */

/** A single weekly availability window. */
export const WindowSchema = z
  .object({
    weekday: z.number().int().min(0).max(6),
    startMinute: z.number().int().min(0).max(1439),
    endMinute: z.number().int().min(0).max(1439),
    timezone: z.string().min(1),
  })
  .refine((w) => w.endMinute > w.startMinute, {
    message: 'endMinute must be greater than startMinute',
    path: ['endMinute'],
  });

export type Window = z.infer<typeof WindowSchema>;

export const SlotDurationSchema = z.union([
  z.literal(15),
  z.literal(30),
  z.literal(45),
  z.literal(60),
]);
export type SlotDuration = z.infer<typeof SlotDurationSchema>;

/** Settings input accepted by `set_office_hours`. */
export const OfficeHoursSettingsSchema = z.object({
  enabled: z.boolean(),
  windows: z.array(WindowSchema).max(40, 'Too many windows'),
  slotDurationMinutes: SlotDurationSchema,
  maxBookingsPerWeek: z.number().int().min(1).max(50),
  bufferMinutes: z.number().int().min(0).max(60),
  meetingLinkTemplate: z
    .preprocess(
      (v) => (typeof v === 'string' && v.trim() === '' ? undefined : v),
      z
        .string()
        .trim()
        .max(500)
        .refine((s) => s.startsWith('https://'), {
          message: 'meeting link must start with https://',
        })
        .optional()
    )
    .optional(),
  notesTemplate: z
    .preprocess(
      (v) => (typeof v === 'string' && v.trim() === '' ? undefined : v),
      z.string().trim().min(1).max(2000).optional()
    )
    .optional(),
});

export type OfficeHoursSettingsInput = z.infer<typeof OfficeHoursSettingsSchema>;

/** Input for the `book_slot` RPC. */
export const BookSlotInputSchema = z.object({
  slotId: z.string().uuid(),
  topic: z.string().trim().min(5).max(280),
});

export type BookSlotInput = z.infer<typeof BookSlotInputSchema>;

/** IANA weekday names keyed by 0=Sunday. */
export const WEEKDAY_KEYS = [
  'weekday_0',
  'weekday_1',
  'weekday_2',
  'weekday_3',
  'weekday_4',
  'weekday_5',
  'weekday_6',
] as const;
