jest.mock('@react-native-async-storage/async-storage', () =>
  require('@react-native-async-storage/async-storage/jest/async-storage-mock')
);

jest.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => {
      const map: Record<string, string> = {
        'settings.telemetry': 'Telemetry',
        'settings.analytics': 'Analytics',
        'settings.crashReports': 'Crash reports',
      };
      return map[key] ?? key;
    },
  }),
}));

import { fireEvent, render } from '@testing-library/react-native';
import { TelemetrySection } from '~/features/settings/components/TelemetrySection';
import { useTelemetryStore } from '~/features/settings/store/telemetryStore';

describe('TelemetrySection', () => {
  beforeEach(() => {
    useTelemetryStore.setState({ analyticsEnabled: true, crashReportsEnabled: true });
  });

  it('renders both toggles with current values', () => {
    const { getByTestId, getByText } = render(<TelemetrySection />);
    expect(getByText('Telemetry')).toBeTruthy();
    expect(getByText('Analytics')).toBeTruthy();
    expect(getByText('Crash reports')).toBeTruthy();
    expect(getByTestId('pref-analytics').props.value).toBe(true);
    expect(getByTestId('pref-crash-reports').props.value).toBe(true);
  });

  it('toggling analytics switch updates the store', () => {
    const { getByTestId } = render(<TelemetrySection />);
    fireEvent(getByTestId('pref-analytics'), 'valueChange', false);
    expect(useTelemetryStore.getState().analyticsEnabled).toBe(false);
  });

  it('toggling crash-reports switch updates the store', () => {
    const { getByTestId } = render(<TelemetrySection />);
    fireEvent(getByTestId('pref-crash-reports'), 'valueChange', false);
    expect(useTelemetryStore.getState().crashReportsEnabled).toBe(false);
  });
});
