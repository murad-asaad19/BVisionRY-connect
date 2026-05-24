import { useTranslation } from 'react-i18next';
import { Pill } from '~/components/ui/Pill';

/**
 * Small "Office hours" pill rendered on UserCard when the profile has
 * office hours enabled. The flag is hydrated by callers (we do not
 * issue a per-card query — that would 404-storm a feed).
 */
export function OfficeHoursBadge() {
  const { t } = useTranslation();
  return (
    <Pill variant="navy" testID="office-hours-badge">
      {t('officeHours.badge.label')}
    </Pill>
  );
}
