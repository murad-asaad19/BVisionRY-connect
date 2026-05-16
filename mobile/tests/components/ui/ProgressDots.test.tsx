import { render } from '@testing-library/react-native';
import { ProgressDots } from '~/components/ui/ProgressDots';

describe('ProgressDots', () => {
  it('renders the requested number of dots', () => {
    const { getByTestId } = render(<ProgressDots steps={4} currentIndex={1} testID="dots" />);
    const container = getByTestId('dots');
    // Each dot is a child View
    expect(container.props.children.length).toBe(4);
  });
});
