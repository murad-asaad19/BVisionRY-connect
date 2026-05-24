jest.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => key,
  }),
}));

import { render, fireEvent } from '@testing-library/react-native';
import { useState } from 'react';
import { WeeklyAvailabilityEditor } from '~/features/office-hours/components/WeeklyAvailabilityEditor';
import type { Window } from '~/features/office-hours/schemas';

function Harness({ initial }: { initial: Window[] }) {
  const [windows, setWindows] = useState<Window[]>(initial);
  return (
    <WeeklyAvailabilityEditor
      windows={windows}
      defaultTimezone="UTC"
      onChange={setWindows}
    />
  );
}

describe('WeeklyAvailabilityEditor', () => {
  it('renders one row per weekday with no windows by default', () => {
    const { getByTestId } = render(<Harness initial={[]} />);
    for (let i = 0; i < 7; i++) {
      expect(getByTestId(`weekly-availability-day-${i}`)).toBeTruthy();
    }
  });

  it('appends a new window to the selected weekday on "add"', () => {
    const { getByTestId, queryByTestId } = render(<Harness initial={[]} />);
    // No row 0 yet.
    expect(queryByTestId('weekly-availability-row-0')).toBeNull();
    fireEvent.press(getByTestId('weekly-availability-add-2')); // Tuesday
    expect(getByTestId('weekly-availability-row-0')).toBeTruthy();
    // default 09:00 → 10:00
    expect(getByTestId('weekly-availability-start-0').props.value).toBe('09:00');
    expect(getByTestId('weekly-availability-end-0').props.value).toBe('10:00');
    // timezone defaults to "UTC"
    expect(getByTestId('weekly-availability-tz-0').props.value).toBe('UTC');
  });

  it('surfaces an inline error when end is not after start', () => {
    const { getByTestId, queryByTestId } = render(
      <Harness
        initial={[
          { weekday: 2, startMinute: 600, endMinute: 660, timezone: 'UTC' },
        ]}
      />
    );
    // Sanity check — no error initially.
    expect(queryByTestId('weekly-availability-error-0')).toBeNull();
    // Set end == start (a clearly invalid value).
    fireEvent.changeText(getByTestId('weekly-availability-end-0'), '10:00');
    fireEvent.changeText(getByTestId('weekly-availability-start-0'), '10:00');
    expect(getByTestId('weekly-availability-error-0')).toBeTruthy();
  });

  it('removes a window when the × button is pressed', () => {
    const { getByTestId, queryByTestId } = render(
      <Harness
        initial={[
          { weekday: 1, startMinute: 600, endMinute: 660, timezone: 'UTC' },
        ]}
      />
    );
    expect(getByTestId('weekly-availability-row-0')).toBeTruthy();
    fireEvent.press(getByTestId('weekly-availability-remove-0'));
    expect(queryByTestId('weekly-availability-row-0')).toBeNull();
  });
});
