import { render, fireEvent } from '@testing-library/react-native';
import { ConversationListRow } from '~/features/chat/components/ConversationListRow';

describe('ConversationListRow', () => {
  const baseProps = {
    peerName: 'Ada',
    peerHandle: 'ada',
    peerPhotoUrl: null,
    lastMessagePreview: 'Hey there',
    onPress: jest.fn(),
  };

  it('renders peer name + handle + preview', () => {
    const { getByText } = render(<ConversationListRow {...baseProps} />);
    expect(getByText('Ada')).toBeTruthy();
    expect(getByText('@ada')).toBeTruthy();
    expect(getByText('Hey there')).toBeTruthy();
  });

  it('shows an unread badge with the count when unreadCount > 0', () => {
    const { getByTestId, getByText } = render(
      <ConversationListRow {...baseProps} unreadCount={3} />
    );
    expect(getByTestId('conversation-row-unread-badge')).toBeTruthy();
    expect(getByText('3')).toBeTruthy();
  });

  it('clamps unread badge at 99+', () => {
    const { getByText } = render(<ConversationListRow {...baseProps} unreadCount={250} />);
    expect(getByText('99+')).toBeTruthy();
  });

  it('shows the mute indicator when isMuted', () => {
    const { getByTestId } = render(<ConversationListRow {...baseProps} isMuted />);
    expect(getByTestId('conversation-row-muted')).toBeTruthy();
  });

  it('omits unread badge when unreadCount = 0', () => {
    const { queryByTestId } = render(<ConversationListRow {...baseProps} unreadCount={0} />);
    expect(queryByTestId('conversation-row-unread-badge')).toBeNull();
  });

  it('fires onPress when tapped', () => {
    const onPress = jest.fn();
    const { getByTestId } = render(<ConversationListRow {...baseProps} onPress={onPress} />);
    fireEvent.press(getByTestId('conversation-row-ada'));
    expect(onPress).toHaveBeenCalled();
  });
});
