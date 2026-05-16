import { render, fireEvent } from '@testing-library/react-native';
import { Input } from '~/components/ui/Input';

describe('Input', () => {
  it('renders value + label + placeholder', () => {
    const { getByDisplayValue, getByText, getByPlaceholderText } = render(
      <Input
        label="Email"
        value="foo@bar"
        onChangeText={() => {}}
        placeholder="enter email"
      />
    );
    expect(getByText('Email')).toBeTruthy();
    expect(getByDisplayValue('foo@bar')).toBeTruthy();
    expect(getByPlaceholderText('enter email')).toBeTruthy();
  });

  it('fires onChangeText', () => {
    const onChangeText = jest.fn();
    const { getByTestId } = render(
      <Input testID="i" value="" onChangeText={onChangeText} />
    );
    fireEvent.changeText(getByTestId('i'), 'hello');
    expect(onChangeText).toHaveBeenCalledWith('hello');
  });
});
