import { render, fireEvent } from '@testing-library/react-native';
import { Text } from 'react-native';
import { Card } from '~/components/ui/Card';

describe('Card', () => {
  it('renders children', () => {
    const { getByText } = render(
      <Card>
        <Text>Inside</Text>
      </Card>
    );
    expect(getByText('Inside')).toBeTruthy();
  });

  it('fires onPress when set', () => {
    const onPress = jest.fn();
    const { getByTestId } = render(
      <Card testID="c" onPress={onPress}>
        <Text>x</Text>
      </Card>
    );
    fireEvent.press(getByTestId('c'));
    expect(onPress).toHaveBeenCalledTimes(1);
  });

  it('renders featured variant', () => {
    const { getByTestId } = render(
      <Card testID="c" variant="featured">
        <Text>x</Text>
      </Card>
    );
    expect(getByTestId('c')).toBeTruthy();
  });
});
