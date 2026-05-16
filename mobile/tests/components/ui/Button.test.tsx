import { render, fireEvent } from '@testing-library/react-native';
import { Button } from '~/components/ui/Button';

describe('Button', () => {
  it('renders children and fires onPress', () => {
    const onPress = jest.fn();
    const { getByText, getByTestId } = render(
      <Button testID="b" onPress={onPress}>
        Click me
      </Button>
    );
    expect(getByText('Click me')).toBeTruthy();
    fireEvent.press(getByTestId('b'));
    expect(onPress).toHaveBeenCalledTimes(1);
  });

  it('does not fire onPress when disabled', () => {
    const onPress = jest.fn();
    const { getByTestId } = render(
      <Button testID="b" onPress={onPress} disabled>
        X
      </Button>
    );
    fireEvent.press(getByTestId('b'));
    expect(onPress).not.toHaveBeenCalled();
  });

  it('renders all variants without crashing', () => {
    const { rerender } = render(<Button variant="primary">X</Button>);
    for (const v of ['gold', 'outline', 'danger', 'disabled'] as const) {
      rerender(<Button variant={v}>X</Button>);
    }
  });

  it('renders size=small', () => {
    const { getByText } = render(<Button size="small">tiny</Button>);
    expect(getByText('tiny')).toBeTruthy();
  });
});
