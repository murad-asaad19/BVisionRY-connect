jest.mock('expo-application', () => ({
  nativeApplicationVersion: '1.2.3',
  nativeBuildVersion: '42',
}));

jest.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => {
      const map: Record<string, string> = {
        'settings.about': 'About',
        'settings.version': 'Version',
      };
      return map[key] ?? key;
    },
  }),
}));

import { render } from '@testing-library/react-native';
import { AppVersionSection } from '~/features/settings/components/AppVersionSection';

describe('AppVersionSection', () => {
  it('renders version and build number from expo-application', () => {
    const { getByTestId, getByText } = render(<AppVersionSection />);
    const node = getByTestId('app-version');
    expect(node).toBeTruthy();
    expect(getByText('Version 1.2.3 (42)')).toBeTruthy();
    expect(getByText('About')).toBeTruthy();
  });
});
