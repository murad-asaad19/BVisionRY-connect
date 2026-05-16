jest.mock('~/features/media/services/storage.service', () => ({
  getChatMediaSignedUrl: jest.fn(() => Promise.resolve('https://example/img.jpg')),
}));

import { render, fireEvent, waitFor } from '@testing-library/react-native';
import { ImageMessageBubble } from '~/features/media/components/ImageMessageBubble';

describe('ImageMessageBubble', () => {
  it('renders image bubble and viewer modal on tap', async () => {
    const { getByTestId } = render(<ImageMessageBubble mediaPath="conv/msg/x.jpg" isMine />);
    const bubble = await waitFor(() => getByTestId('image-bubble-mine'));
    expect(bubble).toBeTruthy();
    fireEvent.press(bubble);
    expect(getByTestId('image-viewer-backdrop')).toBeTruthy();
  });
});
