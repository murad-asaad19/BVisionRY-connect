import { supabase } from '~/lib/supabase/client';
import { OnboardingSubmissionSchema, type OnboardingSubmission } from '~/features/profile/schemas';

export async function submitOnboarding(userId: string, draft: OnboardingSubmission) {
  const parsed = OnboardingSubmissionSchema.parse(draft);
  const { data, error } = await supabase
    .from('profiles')
    .update({
      name: parsed.name,
      handle: parsed.handle,
      roles: parsed.roles,
      primary_role: parsed.primary_role,
      goal_type: parsed.goal_type,
      goal_text: parsed.goal_text,
      city: parsed.city,
      country: parsed.country,
      headline: parsed.headline || null,
      bio: parsed.bio || null,
      onboarded: true,
    })
    .eq('id', userId)
    .select()
    .single();
  if (error) throw new Error(error.message);
  return data;
}
