import { render, fireEvent } from '@testing-library/react-native';
import { Text } from 'react-native';
import { TopBar } from '~/components/ui/TopBar';

describe('TopBar', () => {
  it('renders title', () => {
    const { getByText } = render(<TopBar title="Home" />);
    expect(getByText('Home')).toBeTruthy();
  });

  it('fires action onPress', () => {
    const onPress = jest.fn();
    const { getByTestId } = render(
      <TopBar
        title="Home"
        actions={[
          {
            icon: <Text>⚙</Text>,
            onPress,
            accessibilityLabel: 'Settings',
            testID: 'act-1',
          },
        ]}
      />
    );
    fireEvent.press(getByTestId('act-1'));
    expect(onPress).toHaveBeenCalled();
  });
});
