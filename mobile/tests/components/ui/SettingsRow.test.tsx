import { render, fireEvent } from '@testing-library/react-native';
import { Text } from 'react-native';
import { SettingsRow } from '~/components/ui/SettingsRow';

describe('SettingsRow', () => {
  it('renders label and description', () => {
    const { getByText } = render(<SettingsRow label="Account" description="Email and password" />);
    expect(getByText('Account')).toBeTruthy();
    expect(getByText('Email and password')).toBeTruthy();
  });

  it('fires onPress', () => {
    const onPress = jest.fn();
    const { getByTestId } = render(
      <SettingsRow testID="row" label="Account" onPress={onPress} />
    );
    fireEvent.press(getByTestId('row'));
    expect(onPress).toHaveBeenCalledTimes(1);
  });

  it('renders rightSlot when provided', () => {
    const { getByText } = render(
      <SettingsRow label="Account" rightSlot={<Text>RIGHT</Text>} />
    );
    expect(getByText('RIGHT')).toBeTruthy();
  });
});
