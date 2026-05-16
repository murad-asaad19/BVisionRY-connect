import { render } from '@testing-library/react-native';
import { AvatarCircle } from '~/components/ui/AvatarCircle';

describe('AvatarCircle', () => {
  it('renders the initials uppercased from the name', () => {
    const { getByText } = render(<AvatarCircle name="ahmad" size={48} />);
    expect(getByText('A')).toBeTruthy();
  });

  it('uses both initials when name has multiple words', () => {
    const { getByText } = render(<AvatarCircle name="Alice Bob" size={48} />);
    expect(getByText('AB')).toBeTruthy();
  });

  it('renders ? when name is empty', () => {
    const { getByText } = render(<AvatarCircle name="" size={48} />);
    expect(getByText('?')).toBeTruthy();
  });

  it('renders the avatar-circle testID by default', () => {
    const { getByTestId } = render(<AvatarCircle name="ahmad" size={48} />);
    expect(getByTestId('avatar-circle')).toBeTruthy();
  });

  it('accepts a custom testID', () => {
    const { getByTestId } = render(
      <AvatarCircle testID="custom-avatar" name="ahmad" size={48} />
    );
    expect(getByTestId('custom-avatar')).toBeTruthy();
  });

  it('renders an Image and no initials text when photoUrl is set', () => {
    const { queryByText } = render(
      <AvatarCircle name="ahmad" photoUrl="https://example.com/a.png" size={48} />
    );
    expect(queryByText('A')).toBeNull();
  });

  it('supports the featured size variants (76, 38)', () => {
    const { getByText: getSmall } = render(<AvatarCircle name="x" size={38} />);
    expect(getSmall('X')).toBeTruthy();
    const { getByText: getLarge } = render(<AvatarCircle name="x" size={76} />);
    expect(getLarge('X')).toBeTruthy();
  });
});
