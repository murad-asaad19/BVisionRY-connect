import { View, Text } from 'react-native';
import type { ReactNode } from 'react';

type Props = {
  /** Uppercase eyebrow rendered above the children. Omit for headerless cards. */
  title?: string;
  testID?: string;
  className?: string;
  children: ReactNode;
};

/**
 * Standard surface card used for the section blocks on profile-style screens.
 * Extracts the duplicated local `Section` components from `ProfileView`,
 * `OtherProfileView`, and `PublicProfileView` (audit P1-6).
 */
export function SectionCard({ title, testID, className, children }: Props) {
  return (
    <View
      testID={testID}
      className={`bg-white mx-gutter mt-3 rounded-xl border border-border p-card-lg ${className ?? ''}`}
    >
      {title ? (
        <Text className="font-display-bold text-display-xs text-muted uppercase tracking-wide mb-1.5">
          {title}
        </Text>
      ) : null}
      {children}
    </View>
  );
}
