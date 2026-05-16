import { render, fireEvent } from '@testing-library/react-native';
import { UserCard } from '~/components/ui/UserCard';

describe('UserCard', () => {
  it('renders name + handle + role', () => {
    const { getByText } = render(
      <UserCard
        name="Alice"
        handle="alice"
        primaryRole="Builder"
        photoUrl={null}
        headline="Founder of X"
      />
    );
    expect(getByText('Alice')).toBeTruthy();
    expect(getByText('Founder of X')).toBeTruthy();
  });

  it('fires onPress', () => {
    const onPress = jest.fn();
    const { getByTestId } = render(
      <UserCard
        testID="uc"
        name="Alice"
        handle="alice"
        primaryRole="Builder"
        photoUrl={null}
        onPress={onPress}
      />
    );
    fireEvent.press(getByTestId('uc'));
    expect(onPress).toHaveBeenCalled();
  });

  it('renders reason as a pill when provided', () => {
    const { getByText } = render(
      <UserCard
        name="Alice"
        handle="alice"
        primaryRole="Builder"
        photoUrl={null}
        reason="Shared role"
      />
    );
    expect(getByText('Shared role')).toBeTruthy();
  });

  it('shows verified badge when verified=true', () => {
    const { getByText } = render(
      <UserCard
        name="Alice"
        handle="alice"
        primaryRole="Builder"
        photoUrl={null}
        verified
      />
    );
    expect(getByText(/✓/)).toBeTruthy();
  });
});
