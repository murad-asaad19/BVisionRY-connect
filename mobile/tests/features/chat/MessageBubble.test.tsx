jest.mock('~/lib/supabase/client', () => ({
  supabase: { rpc: jest.fn(), from: jest.fn() },
}));

jest.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => {
      const map: Record<string, string> = {
        'chat.deletedPlaceholder': 'Message deleted',
        'chat.edited': 'edited',
        'chat.edit': 'Edit',
        'chat.delete': 'Delete',
        'chat.save': 'Save',
        'chat.cancel': 'Cancel',
      };
      return map[key] ?? key;
    },
  }),
}));

jest.mock('expo-audio', () => ({
  useAudioPlayer: jest.fn(() => ({ play: jest.fn(), pause: jest.fn() })),
  useAudioPlayerStatus: jest.fn(() => ({ playing: false })),
  useAudioRecorder: jest.fn(() => ({
    prepareToRecordAsync: jest.fn(),
    record: jest.fn(),
    stop: jest.fn(),
    uri: null,
  })),
  useAudioRecorderState: jest.fn(() => ({ isRecording: false })),
  RecordingPresets: { HIGH_QUALITY: {} },
}));

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render } from '@testing-library/react-native';
import type { ComponentProps } from 'react';
import { MessageBubble } from '~/features/chat/components/MessageBubble';

const baseMessage = {
  id: 'm1',
  body: 'hello',
  kind: 'text' as const,
  meeting_proposal_id: null,
  sender_id: 'me',
  media_path: null,
  media_duration_ms: null,
  created_at: new Date().toISOString(),
  edited_at: null,
  deleted_at: null,
  transcript: null,
  transcript_status: null,
};

function renderBubble(props: Partial<ComponentProps<typeof MessageBubble>> = {}) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(
    <QueryClientProvider client={client}>
      <MessageBubble
        message={baseMessage}
        isMine={false}
        proposal={null}
        conversationId="c1"
        myId="me"
        {...props}
      />
    </QueryClientProvider>
  );
}

describe('MessageBubble', () => {
  it('renders the body text on a text message', () => {
    const { getByText } = renderBubble();
    expect(getByText('hello')).toBeTruthy();
  });
  it('mine testID', () => {
    const { getByTestId } = renderBubble({ isMine: true });
    expect(getByTestId('message-bubble-mine')).toBeTruthy();
  });
  it('theirs testID', () => {
    const { getByTestId } = renderBubble({ isMine: false });
    expect(getByTestId('message-bubble-theirs')).toBeTruthy();
  });
  it('renders deleted placeholder when deleted_at is set', () => {
    const deleted = { ...baseMessage, body: null, deleted_at: new Date().toISOString() };
    const { getByTestId, getByText } = renderBubble({ message: deleted });
    expect(getByTestId('message-deleted-placeholder')).toBeTruthy();
    expect(getByText('Message deleted')).toBeTruthy();
  });
  it('renders an "(edited)" suffix when edited_at is set', () => {
    const edited = { ...baseMessage, edited_at: new Date().toISOString() };
    const { getByTestId, getByText } = renderBubble({ message: edited });
    expect(getByTestId('message-edited-suffix')).toBeTruthy();
    expect(getByText('(edited)')).toBeTruthy();
  });
});
