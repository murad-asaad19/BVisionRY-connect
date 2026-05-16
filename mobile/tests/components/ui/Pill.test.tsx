import { render } from '@testing-library/react-native';
import { Pill } from '~/components/ui/Pill';

describe('Pill', () => {
  it('renders children', () => {
    const { getByText } = render(<Pill>Hello</Pill>);
    expect(getByText('Hello')).toBeTruthy();
  });

  it('renders all variants', () => {
    const variants = [
      'default',
      'solid',
      'navy',
      'outline',
      'success',
      'warning',
      'danger',
      'muted',
    ] as const;
    const { rerender } = render(<Pill variant="default">x</Pill>);
    for (const v of variants) {
      rerender(<Pill variant={v}>x</Pill>);
    }
  });
});
