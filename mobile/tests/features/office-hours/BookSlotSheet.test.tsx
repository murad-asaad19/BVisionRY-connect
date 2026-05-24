jest.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string, params?: Record<string, string | number>) =>
      params?.hostName ? `${key}:${params.hostName}` : key,
  }),
}));

const mockMutate = jest.fn();
jest.mock('~/features/office-hours/hooks/useBookSlot', () => ({
  useBookSlot: () => ({
    mutateAsync: mockMutate,
    isPending: false,
  }),
}));

import { render, fireEvent, act } from '@testing-library/react-native';
import { BookSlotSheet } from '~/features/office-hours/components/BookSlotSheet';

// Zod 4's `.uuid()` validates strict RFC 4122 variant bits; use a real v4 here.
const SLOT_UUID = 'd9b1d7e7-7f6f-4a8e-9b6f-1f2a3b4c5d6e';

const slot = {
  id: SLOT_UUID,
  startsAt: '2026-06-09T14:00:00Z',
  endsAt: '2026-06-09T14:30:00Z',
  hostNotesTemplate: null,
};

describe('BookSlotSheet', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('surfaces an inline error when topic is too short', async () => {
    const onClose = jest.fn();
    const { getByTestId } = render(
      <BookSlotSheet
        visible
        hostId="h1"
        hostName="Alice"
        slot={slot}
        onClose={onClose}
      />
    );
    fireEvent.changeText(getByTestId('book-slot-topic'), 'hi');
    await act(async () => {
      fireEvent.press(getByTestId('book-slot-submit'));
    });
    expect(mockMutate).not.toHaveBeenCalled();
    expect(getByTestId('book-slot-topic-error')).toBeTruthy();
    expect(onClose).not.toHaveBeenCalled();
  });

  it('calls the mutation and closes on success', async () => {
    mockMutate.mockResolvedValueOnce('p1');
    const onClose = jest.fn();
    const onBooked = jest.fn();
    const { getByTestId } = render(
      <BookSlotSheet
        visible
        hostId="h1"
        hostName="Alice"
        slot={slot}
        onClose={onClose}
        onBooked={onBooked}
      />
    );
    fireEvent.changeText(
      getByTestId('book-slot-topic'),
      'A great topic for our chat together'
    );
    await act(async () => {
      fireEvent.press(getByTestId('book-slot-submit'));
    });
    expect(mockMutate).toHaveBeenCalledWith({
      hostId: 'h1',
      slotId: SLOT_UUID,
      topic: 'A great topic for our chat together',
    });
    expect(onBooked).toHaveBeenCalledWith('p1');
    expect(onClose).toHaveBeenCalled();
  });
});
