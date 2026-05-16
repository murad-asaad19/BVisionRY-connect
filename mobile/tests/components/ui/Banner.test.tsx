import { render } from '@testing-library/react-native';
import { Text } from 'react-native';
import { Banner } from '~/components/ui/Banner';

describe('Banner', () => {
  it('renders title + children', () => {
    const { getByText } = render(
      <Banner variant="info" title="Hello">
        <Text>Body</Text>
      </Banner>
    );
    expect(getByText('Hello')).toBeTruthy();
    expect(getByText('Body')).toBeTruthy();
  });

  it('renders all variants', () => {
    const { rerender } = render(
      <Banner variant="warning">
        <Text>x</Text>
      </Banner>
    );
    for (const v of ['info', 'success', 'muted'] as const) {
      rerender(
        <Banner variant={v}>
          <Text>x</Text>
        </Banner>
      );
    }
  });
});
