import { render } from '@testing-library/react-native';
import { ProfileHero } from '~/features/profile/components/ProfileHero';

describe('ProfileHero', () => {
  it('renders name, handle, and roles', () => {
    const { getByText, getByTestId } = render(
      <ProfileHero
        name="Ada Lovelace"
        handle="ada"
        headline="Math meets machinery"
        primaryRole="builder"
        roles={['builder', 'founder']}
        city="London"
        country="UK"
        photoUrl={null}
      />
    );
    expect(getByTestId('profile-hero-name')).toBeTruthy();
    expect(getByTestId('profile-hero-handle')).toBeTruthy();
    expect(getByText('Ada Lovelace')).toBeTruthy();
    expect(getByText('@ada')).toBeTruthy();
    expect(getByText('builder')).toBeTruthy();
    expect(getByText('founder')).toBeTruthy();
  });
});
