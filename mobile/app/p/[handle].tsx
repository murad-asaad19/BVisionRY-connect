import { useEffect, useState } from 'react';
import { View, Text, ActivityIndicator } from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { useAuthSession } from '~/features/auth/SessionContext';
import { OtherProfileView } from '~/features/profile/components/OtherProfileView';
import {
  fetchPublicProfile,
  type PublicProfile,
} from '~/features/profile/services/publicProfile.service';
import { PublicProfileView } from '~/features/profile/components/PublicProfileView';

export default function PublicProfileRoute() {
  const { handle } = useLocalSearchParams<{ handle: string }>();
  const { session, loading: sessionLoading } = useAuthSession();

  if (sessionLoading) {
    return (
      <View className="flex-1 items-center justify-center bg-surface">
        <ActivityIndicator color="#0f3460" />
      </View>
    );
  }

  // Authed users see the rich profile (with intro/block actions).
  if (session) {
    return <OtherProfileView handle={handle ?? ''} />;
  }

  // Unauthed users see the stripped-down public profile.
  return <AnonProfile handle={handle ?? ''} />;
}

function AnonProfile({ handle }: { handle: string }) {
  const [profile, setProfile] = useState<PublicProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    if (!handle) {
      setLoading(false);
      return;
    }
    setLoading(true);
    fetchPublicProfile(handle)
      .then((p) => setProfile(p))
      .catch((e: Error) => setErr(e.message))
      .finally(() => setLoading(false));
  }, [handle]);

  if (loading) {
    return (
      <View className="flex-1 items-center justify-center bg-surface">
        <ActivityIndicator color="#0f3460" />
      </View>
    );
  }
  if (err) {
    return (
      <View className="flex-1 items-center justify-center bg-surface p-6">
        <Text testID="public-profile-error" className="font-body text-body text-center">
          {err}
        </Text>
      </View>
    );
  }
  if (!profile) {
    return (
      <View className="flex-1 items-center justify-center bg-surface p-6">
        <Text testID="public-profile-not-found" className="font-body text-muted text-center">
          Profile not found.
        </Text>
      </View>
    );
  }
  return <PublicProfileView profile={profile} />;
}
