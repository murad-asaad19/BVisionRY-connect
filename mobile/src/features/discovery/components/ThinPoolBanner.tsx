import { View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Banner } from '~/components/ui/Banner';

type Props = {
  /** Number of strong matches available today. Used in the copy. */
  count?: number;
};

export function ThinPoolBanner({ count }: Props) {
  const { t } = useTranslation();
  const n = count ?? 0;
  // i18next's `count` interpolation resolves to `_one` / `_other` automatically.
  return (
    <View testID="thin-pool-banner" className="mx-3 my-2">
      <Banner variant="muted">{t('discovery.thinPoolBanner', { count: n })}</Banner>
    </View>
  );
}
