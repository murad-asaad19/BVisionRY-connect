import { render, fireEvent } from '@testing-library/react-native';
import { Text } from 'react-native';
import { BottomSheet } from '~/components/ui/Modal';

describe('BottomSheet', () => {
  it('renders children only when visible', () => {
    const { queryByText, rerender } = render(
      <BottomSheet visible={false} onClose={() => {}} testID="sheet">
        <Text>Inside</Text>
      </BottomSheet>
    );
    expect(queryByText('Inside')).toBeNull();
    rerender(
      <BottomSheet visible onClose={() => {}} testID="sheet">
        <Text>Inside</Text>
      </BottomSheet>
    );
    expect(queryByText('Inside')).toBeTruthy();
  });

  it('fires onClose when backdrop is tapped', () => {
    const onClose = jest.fn();
    const { getByTestId } = render(
      <BottomSheet visible onClose={onClose} testID="sheet">
        <Text>Inside</Text>
      </BottomSheet>
    );
    fireEvent.press(getByTestId('sheet-backdrop'));
    expect(onClose).toHaveBeenCalledTimes(1);
  });
});
