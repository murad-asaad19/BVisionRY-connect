import { View } from 'react-native';
import { Banner } from '~/components/ui/Banner';

type Props = {
  /** Number of strong matches available today. Used in the copy. */
  count?: number;
};

export function ThinPoolBanner({ count }: Props) {
  const n = count ?? 0;
  return (
    <View testID="thin-pool-banner" className="mx-3 my-2">
      <Banner variant="muted">
        {`We're being picky for you. Only ${n} strong ${n === 1 ? 'match' : 'matches'} today — your goal is specific. We'll keep watching.`}
      </Banner>
    </View>
  );
}
