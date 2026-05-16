import { z } from 'zod';

export const HandleSchema = z
  .string()
  .min(1)
  .max(30)
  .regex(
    /^[a-z0-9](?:[a-z0-9-]{1,28}[a-z0-9])?$/,
    'Handle must be lowercase letters, numbers, hyphens; 1-30 chars; no leading/trailing hyphen.'
  );

export const NameSchema = z.string().trim().min(1).max(80);

const optionalLengthString = (min: number, max: number) =>
  z.preprocess(
    (v) => (typeof v === 'string' && v.trim() === '' ? undefined : v),
    z.string().trim().min(min).max(max).optional()
  );

export const HeadlineSchema = optionalLengthString(5, 120);
export const BioSchema = optionalLengthString(10, 1000);

export const GoalTextSchema = z.string().trim().min(10).max(280);

export const RoleKindSchema = z.enum(['founder', 'leader', 'builder', 'investor']);
export const RolesSchema = z.array(RoleKindSchema).min(1);

export const GoalTypeSchema = z.enum([
  'hire',
  'be_hired',
  'co_found',
  'invest',
  'take_investment',
  'advise',
  'find_advisor',
  'peer_connect',
]);

export const CitySchema = z.string().trim().min(1).max(80);
export const CountrySchema = z.string().trim().min(1).max(80);

export const OnboardingSubmissionSchema = z.object({
  name: NameSchema,
  handle: HandleSchema,
  roles: RolesSchema,
  primary_role: RoleKindSchema,
  goal_type: GoalTypeSchema,
  goal_text: GoalTextSchema,
  city: CitySchema,
  country: CountrySchema,
  headline: HeadlineSchema,
  bio: BioSchema,
});

export type OnboardingSubmission = z.infer<typeof OnboardingSubmissionSchema>;
