import { render } from '@testing-library/react-native';
import { PushToast } from '~/features/push/components/PushToast';
import { useForegroundMessages } from '~/features/push/hooks/useForegroundMessages';

jest.mock('~/features/push/hooks/useForegroundMessages', () => ({
  useForegroundMessages: jest.fn(),
}));

describe('PushToast', () => {
  beforeEach(() => jest.clearAllMocks());

  it('renders nothing when no toast', () => {
    (useForegroundMessages as jest.Mock).mockReturnValue(null);
    const { queryByTestId } = render(<PushToast />);
    expect(queryByTestId('push-toast')).toBeNull();
  });

  it('renders title + body when present', () => {
    (useForegroundMessages as jest.Mock).mockReturnValue({
      title: 'New message',
      body: 'Hello from Bob',
    });
    const { getByTestId, getByText } = render(<PushToast />);
    expect(getByTestId('push-toast')).toBeTruthy();
    expect(getByText('New message')).toBeTruthy();
    expect(getByText('Hello from Bob')).toBeTruthy();
  });
});
