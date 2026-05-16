import { useState } from 'react';
import { View, Text, ScrollView, ActivityIndicator, Pressable } from 'react-native';
import { router } from 'expo-router';
import { useCurrentUserProfile } from '~/features/profile/hooks/useCurrentUserProfile';
import { useUpdateProfile } from '~/features/profile/hooks/useUpdateProfile';
import { AvatarUploadButton } from '~/features/media/components/AvatarUploadButton';
import { GoalRefreshBanner } from '~/features/profile/components/GoalRefreshBanner';
import { Input } from '~/components/ui/Input';
import { Button } from '~/components/ui/Button';
import { Pill } from '~/components/ui/Pill';
import {
  NameSchema,
  HeadlineSchema,
  BioSchema,
  GoalTextSchema,
  CitySchema,
  CountrySchema,
  HandleSchema,
} from '~/features/profile/schemas';
import type { Database } from '~/lib/supabase/types.gen';

type RoleKind = Database['public']['Enums']['role_kind'];
const ROLE_OPTIONS: RoleKind[] = ['founder', 'leader', 'builder', 'investor'];

const HEADLINE_MAX = 120;

export function ProfileEditForm() {
  const { data: profile, isLoading } = useCurrentUserProfile();

  if (isLoading || !profile) {
    return (
      <View className="flex-1 items-center justify-center bg-surface">
        <ActivityIndicator color="#0f3460" />
      </View>
    );
  }

  return <ProfileEditFormBody profile={profile} />;
}

function ProfileEditFormBody({
  profile,
}: {
  profile: NonNullable<ReturnType<typeof useCurrentUserProfile>['data']>;
}) {
  const updateMutation = useUpdateProfile();

  const [name, setName] = useState(profile.name ?? '');
  const [handle, setHandle] = useState(profile.handle ?? '');
  const [headline, setHeadline] = useState(profile.headline ?? '');
  const [bio, setBio] = useState(profile.bio ?? '');
  const [goalText, setGoalText] = useState(profile.goal_text ?? '');
  const [city, setCity] = useState(profile.city ?? '');
  const [country, setCountry] = useState(profile.country ?? '');
  const [roles, setRoles] = useState<RoleKind[]>(profile.roles ?? []);
  const [primaryRole, setPrimaryRole] = useState<RoleKind | undefined>(
    profile.primary_role ?? undefined
  );
  const [error, setError] = useState<string | null>(null);

  const toggleRole = (r: RoleKind) => {
    setRoles((prev) => {
      const next = prev.includes(r) ? prev.filter((x) => x !== r) : [...prev, r];
      if (primaryRole && !next.includes(primaryRole)) setPrimaryRole(next[0]);
      if (!primaryRole && next.length === 1) setPrimaryRole(next[0]);
      return next;
    });
  };

  const onSave = async () => {
    setError(null);
    const checks = [
      NameSchema.safeParse(name),
      HandleSchema.safeParse(handle),
      HeadlineSchema.safeParse(headline),
      BioSchema.safeParse(bio),
      GoalTextSchema.safeParse(goalText),
      CitySchema.safeParse(city),
      CountrySchema.safeParse(country),
    ];
    for (const r of checks) {
      if (!r.success) {
        setError(r.error.issues[0]?.message ?? 'Validation failed');
        return;
      }
    }
    if (roles.length === 0) {
      setError('Pick at least one role.');
      return;
    }
    const effectivePrimary = primaryRole && roles.includes(primaryRole) ? primaryRole : roles[0]!;
    try {
      await updateMutation.mutateAsync({
        name: name.trim(),
        handle: handle.trim().toLowerCase(),
        headline: headline.trim() || null,
        bio: bio.trim() || null,
        goal_text: goalText.trim(),
        city: city.trim(),
        country: country.trim(),
        roles,
        primary_role: effectivePrimary,
      });
      router.back();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Save failed');
    }
  };

  return (
    <ScrollView className="flex-1 bg-surface">
      <View className="px-6 pt-16 pb-8">
        <Text className="font-display-bold text-navy text-2xl mb-4">Edit profile</Text>

        <GoalRefreshBanner goalUpdatedAt={profile.goal_updated_at ?? null} />

        <View className="items-center mb-2">
          <AvatarUploadButton currentPhotoUrl={profile.photo_url ?? null} />
          <Text className="font-body text-[11px] text-muted -mt-2 mb-2">Tap photo to change</Text>
        </View>

        <View className="gap-1">
          <Input testID="edit-name" label="Name" value={name} onChangeText={setName} />
          <Input
            testID="edit-handle"
            label="Handle"
            value={handle}
            onChangeText={(t) => setHandle(t.toLowerCase())}
            autoCapitalize="none"
            placeholder="ahmad"
          />
          <Text className="font-body text-[10px] text-muted leading-snug mb-2">
            Changing your handle later creates a redirect for 90 days, then 410 Gone.
          </Text>

          <View className="flex-row items-end justify-between mb-1">
            <Text className="font-display-semibold text-[10px] text-muted uppercase tracking-wide">
              Headline (optional)
            </Text>
            <Text testID="edit-headline-counter" className="font-body text-[10px] text-muted">
              {headline.length} / {HEADLINE_MAX}
            </Text>
          </View>
          <Input
            testID="edit-headline"
            value={headline}
            onChangeText={setHeadline}
            maxLength={HEADLINE_MAX}
          />

          <Input
            testID="edit-bio"
            label="Bio (optional)"
            value={bio}
            onChangeText={setBio}
            multiline
            numberOfLines={4}
            maxLength={1000}
          />
          <Input
            testID="edit-goal-text"
            label="Goal description"
            value={goalText}
            onChangeText={setGoalText}
            multiline
            numberOfLines={3}
            maxLength={280}
          />
          <Input testID="edit-city" label="City" value={city} onChangeText={setCity} />
          <Input testID="edit-country" label="Country" value={country} onChangeText={setCountry} />

          <Text className="font-display-semibold text-[10px] text-muted uppercase tracking-wide mt-2 mb-1.5">
            Roles
          </Text>
          <View className="flex-row flex-wrap gap-2 mb-1">
            {ROLE_OPTIONS.map((r) => {
              const selected = roles.includes(r);
              return (
                <Pressable
                  key={r}
                  testID={`edit-role-${r}`}
                  onPress={() => toggleRole(r)}
                  accessibilityRole="button"
                  accessibilityState={{ selected }}
                >
                  <Pill variant={selected ? 'solid' : 'outline'}>
                    {r}
                    {selected ? ' ✓' : ''}
                  </Pill>
                </Pressable>
              );
            })}
          </View>
          {roles.length > 1 ? (
            <View className="mb-2">
              <Text className="font-display-semibold text-[10px] text-muted uppercase tracking-wide mt-2 mb-1.5">
                Primary role
              </Text>
              <View className="flex-row flex-wrap gap-2">
                {roles.map((r) => (
                  <Pressable
                    key={r}
                    testID={`edit-primary-${r}`}
                    onPress={() => setPrimaryRole(r)}
                    accessibilityRole="button"
                    accessibilityState={{ selected: primaryRole === r }}
                  >
                    <Pill variant={primaryRole === r ? 'solid' : 'outline'}>{r}</Pill>
                  </Pressable>
                ))}
              </View>
            </View>
          ) : null}

          {error && (
            <Text testID="edit-error" className="text-danger-text font-body mt-2">
              {error}
            </Text>
          )}

          <View className="flex-row gap-3 mt-4">
            <View className="flex-1">
              <Button testID="edit-cancel" variant="outline" onPress={() => router.back()}>
                Cancel
              </Button>
            </View>
            <View className="flex-1">
              <Button
                testID="edit-save"
                variant="primary"
                onPress={onSave}
                loading={updateMutation.isPending}
              >
                Save
              </Button>
            </View>
          </View>
        </View>
      </View>
    </ScrollView>
  );
}
