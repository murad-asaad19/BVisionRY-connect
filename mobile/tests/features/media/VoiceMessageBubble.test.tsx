jest.mock('~/features/media/services/storage.service', () => ({
  getChatMediaSignedUrl: jest.fn(() => Promise.resolve('https://example/audio.m4a')),
}));

jest.mock('expo-audio', () => ({
  useAudioPlayer: jest.fn(() => ({ play: jest.fn(), pause: jest.fn() })),
  useAudioPlayerStatus: jest.fn(() => ({ playing: false })),
}));

import { render } from '@testing-library/react-native';
import { VoiceMessageBubble } from '~/features/media/components/VoiceMessageBubble';

describe('VoiceMessageBubble', () => {
  it('renders duration label and toggle button', () => {
    const { getByTestId, getByText } = render(
      <VoiceMessageBubble mediaPath="x" durationMs={62_000} isMine={false} />
    );
    expect(getByTestId('voice-bubble-theirs')).toBeTruthy();
    expect(getByTestId('voice-toggle')).toBeTruthy();
    expect(getByText(/1:02/)).toBeTruthy();
  });
});
