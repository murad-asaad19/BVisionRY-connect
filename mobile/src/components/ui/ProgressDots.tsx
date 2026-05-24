import { View } from 'react-native';

type Props = { steps: number; currentIndex: number; testID?: string };

export function ProgressDots({ steps, currentIndex, testID }: Props) {
  return (
    <View
      testID={testID}
      accessibilityRole="progressbar"
      accessibilityValue={{ min: 0, max: steps, now: currentIndex }}
      className="flex-row gap-1.5 mb-4"
    >
      {Array.from({ length: steps }).map((_, i) => {
        const bg = i < currentIndex ? 'bg-gold' : i === currentIndex ? 'bg-navy' : 'bg-border';
        return <View key={i} className={`flex-1 h-1 rounded-sm ${bg}`} />;
      })}
    </View>
  );
}
