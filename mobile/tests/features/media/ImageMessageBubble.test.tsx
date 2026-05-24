jest.mock('~/features/media/services/storage.service', () => ({
  getChatMediaSignedUrl: jest.fn(() => Promise.resolve('https://example/img.jpg')),
}));
jest.mock('~/features/media/hooks/useSignedUrl', () => ({
  useSignedUrl: jest.fn(),
}));
// Replace expo-image's Image with a plain RN View that surfaces its `onError`
// prop via a testID so we can trigger the stale-URL refetch path without
// booting the real native ImageLoader.
jest.mock('expo-image', () => {
  const React = require('react');
  const { View } = require('react-native');
  return {
    __esModule: true,
    Image: (props: Record<string, unknown>) =>
      React.createElement(View, { ...props, testID: 'expo-image' }),
  };
});

import { fireEvent, waitFor } from '@testing-library/react-native';
import { ImageMessageBubble } from '~/features/media/components/ImageMessageBubble';
import { useSignedUrl } from '~/features/media/hooks/useSignedUrl';
import { renderWithProviders } from '../../helpers/renderWithProviders';

const mockedUseSignedUrl = useSignedUrl as jest.MockedFunction<typeof useSignedUrl>;

describe('ImageMessageBubble', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders image bubble and viewer modal on tap', async () => {
    mockedUseSignedUrl.mockReturnValue({
      data: 'https://example/img.jpg',
      refetch: jest.fn(),
    } as unknown as ReturnType<typeof useSignedUrl>);

    const { getByTestId } = renderWithProviders(
      <ImageMessageBubble mediaPath="conv/msg/x.jpg" isMine />
    );
    const bubble = await waitFor(() => getByTestId('image-bubble-mine'));
    expect(bubble).toBeTruthy();
    fireEvent.press(bubble);
    expect(getByTestId('image-viewer-backdrop')).toBeTruthy();
  });

  it('refetches the signed URL when expo-image onError fires', async () => {
    // Supabase signed URLs expire (default ~1h). Stale URLs trigger an
    // `onError` on expo-image; the bubble must refetch a fresh URL rather
    // than render a permanent broken-image placeholder.
    const refetch = jest.fn();
    mockedUseSignedUrl.mockReturnValue({
      data: 'https://example/expired.jpg',
      refetch,
    } as unknown as ReturnType<typeof useSignedUrl>);

    const { getByTestId } = renderWithProviders(
      <ImageMessageBubble mediaPath="conv/msg/x.jpg" isMine={false} />
    );

    // The mocked expo-image forwards props (including onError) onto a plain
    // View, so we can use the standard event firer to trigger the callback.
    fireEvent(getByTestId('expo-image'), 'error');

    expect(refetch).toHaveBeenCalledTimes(1);
  });
});
