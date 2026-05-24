import { z } from 'zod';

/**
 * Zod schemas matching the DB constraints in
 * supabase/migrations/20260608020000_opportunities.sql. Keep these in
 * lockstep with the migration — the DB is the source of truth and the
 * schemas are the client-side mirror for inline error UX.
 */

export const OpportunityKindSchema = z.enum([
  'hiring',
  'seeking_role',
  'fundraising',
  'investing',
  'cofounder',
  'advising',
  'seeking_advisor',
  'collaboration',
]);

export const OpportunityStatusSchema = z.enum(['open', 'closed', 'archived']);

/** Single tag: lowercase, 1-30 chars, no surrounding whitespace. */
export const OpportunityTagSchema = z
  .string()
  .trim()
  .min(1)
  .max(30)
  .refine((s) => s === s.toLowerCase(), { message: 'tag must be lowercase' });

export const OpportunityTitleSchema = z.string().trim().min(5).max(120);
export const OpportunityBodySchema = z.string().trim().min(10).max(2000);
export const OpportunityTagsSchema = z.array(OpportunityTagSchema).max(8).default([]);

const optionalShortText = (max: number) =>
  z.preprocess(
    (v) => (typeof v === 'string' && v.trim() === '' ? undefined : v),
    z.string().trim().min(1).max(max).optional()
  );

export const OpportunityLocationCitySchema = optionalShortText(80);
export const OpportunityLocationCountrySchema = optionalShortText(80);

/** Input accepted by `createOpportunity` + `updateOpportunity`. */
export const CreateOpportunityInputSchema = z.object({
  kind: OpportunityKindSchema,
  title: OpportunityTitleSchema,
  body: OpportunityBodySchema,
  tags: OpportunityTagsSchema,
  locationCity: OpportunityLocationCitySchema,
  locationCountry: OpportunityLocationCountrySchema,
  remoteOk: z.boolean().default(false),
  /** ISO-8601 timestamptz; null = 30d default applied server-side. */
  expiresAt: z.string().datetime().nullable().optional(),
});

export type CreateOpportunityInput = z.infer<typeof CreateOpportunityInputSchema>;

/** Input for `expressInterest` — note is optional but bounded when present. */
export const ExpressInterestInputSchema = z.object({
  opportunityId: z.string().uuid(),
  note: z.preprocess(
    (v) => (typeof v === 'string' && v.trim() === '' ? undefined : v),
    z.string().trim().min(10).max(500).optional()
  ),
});

export type ExpressInterestInput = z.infer<typeof ExpressInterestInputSchema>;
