jest.mock('~/lib/supabase/client', () => ({
  supabase: { rpc: jest.fn() },
}));

import { supabase } from '~/lib/supabase/client';
import {
  getMyOfficeHoursSettings,
  setOfficeHours,
  listUpcomingSlots,
  bookSlot,
  cancelBooking,
  listMyBookings,
  OfficeHoursError,
  OfficeHoursForbiddenError,
  OfficeHoursValidationError,
  SlotUnavailableError,
  MaxBookingsReachedError,
  SlotNotFoundError,
} from '~/features/office-hours/services/officeHours.service';

describe('officeHours.service', () => {
  beforeEach(() => jest.clearAllMocks());

  describe('getMyOfficeHoursSettings', () => {
    it('maps the row to camelCase', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: {
          user_id: 'u1',
          enabled: true,
          windows: [
            { weekday: 2, start_minute: 540, end_minute: 600, timezone: 'UTC' },
          ],
          slot_duration_minutes: 30,
          max_bookings_per_week: 5,
          buffer_minutes: 5,
          meeting_link_template: 'https://meet.example/{slot_id}',
          notes_template: 'bring a question',
          updated_at: '2026-05-24T12:00:00Z',
        },
        error: null,
      });
      const settings = await getMyOfficeHoursSettings();
      expect(supabase.rpc).toHaveBeenCalledWith('my_office_hours_settings', {});
      expect(settings).toEqual({
        userId: 'u1',
        enabled: true,
        windows: [
          { weekday: 2, startMinute: 540, endMinute: 600, timezone: 'UTC' },
        ],
        slotDurationMinutes: 30,
        maxBookingsPerWeek: 5,
        bufferMinutes: 5,
        meetingLinkTemplate: 'https://meet.example/{slot_id}',
        notesTemplate: 'bring a question',
        updatedAt: '2026-05-24T12:00:00Z',
      });
    });

    it('maps 28000 errors to OfficeHoursError (unknown code path)', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { code: '28000', message: 'unauthenticated' },
      });
      await expect(getMyOfficeHoursSettings()).rejects.toBeInstanceOf(OfficeHoursError);
    });
  });

  describe('setOfficeHours', () => {
    it('serializes camelCase windows to snake_case args', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: {
          user_id: 'u1',
          enabled: true,
          windows: [
            { weekday: 1, start_minute: 600, end_minute: 660, timezone: 'UTC' },
          ],
          slot_duration_minutes: 30,
          max_bookings_per_week: 3,
          buffer_minutes: 10,
          meeting_link_template: null,
          notes_template: null,
          updated_at: '2026-05-24T12:00:00Z',
        },
        error: null,
      });
      await setOfficeHours({
        enabled: true,
        windows: [
          { weekday: 1, startMinute: 600, endMinute: 660, timezone: 'UTC' },
        ],
        slotDurationMinutes: 30,
        maxBookingsPerWeek: 3,
        bufferMinutes: 10,
      });
      expect(supabase.rpc).toHaveBeenCalledWith('set_office_hours', {
        p_enabled: true,
        p_windows: [
          { weekday: 1, start_minute: 600, end_minute: 660, timezone: 'UTC' },
        ],
        p_slot_duration_minutes: 30,
        p_max_bookings_per_week: 3,
        p_buffer_minutes: 10,
        p_meeting_link_template: null,
        p_notes_template: null,
      });
    });

    it('maps a 22023 validation error to OfficeHoursValidationError', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { code: '22023', message: 'window.timezone must be a valid IANA timezone name' },
      });
      await expect(
        setOfficeHours({
          enabled: true,
          windows: [{ weekday: 1, startMinute: 0, endMinute: 60, timezone: 'X' }],
          slotDurationMinutes: 30,
          maxBookingsPerWeek: 3,
          bufferMinutes: 5,
        })
      ).rejects.toBeInstanceOf(OfficeHoursValidationError);
    });
  });

  describe('listUpcomingSlots', () => {
    it('maps rows + passes host id', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: [
          {
            id: 's1',
            starts_at: '2026-06-09T14:00:00Z',
            ends_at: '2026-06-09T14:30:00Z',
            host_settings_notes_template: 'bring a question',
          },
        ],
        error: null,
      });
      const rows = await listUpcomingSlots('h1');
      expect(supabase.rpc).toHaveBeenCalledWith('list_upcoming_slots', { p_host: 'h1' });
      expect(rows).toEqual([
        {
          id: 's1',
          startsAt: '2026-06-09T14:00:00Z',
          endsAt: '2026-06-09T14:30:00Z',
          hostNotesTemplate: 'bring a question',
        },
      ]);
    });

    it('returns [] for null data', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: null });
      expect(await listUpcomingSlots('h1')).toEqual([]);
    });
  });

  describe('bookSlot', () => {
    it('returns the new meeting_proposal id', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: 'p1', error: null });
      const id = await bookSlot('s1', 'A great topic for our chat');
      expect(supabase.rpc).toHaveBeenCalledWith('book_slot', {
        p_slot_id: 's1',
        p_topic: 'A great topic for our chat',
      });
      expect(id).toBe('p1');
    });

    it('maps "max bookings" 22023 to MaxBookingsReachedError', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { code: '22023', message: 'max bookings per week with this host reached' },
      });
      await expect(bookSlot('s1', 'topic words')).rejects.toBeInstanceOf(MaxBookingsReachedError);
    });

    it('maps "slot is not open" 22023 to SlotUnavailableError', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { code: '22023', message: 'slot is not open' },
      });
      await expect(bookSlot('s1', 'topic words')).rejects.toBeInstanceOf(SlotUnavailableError);
    });

    it('maps P0002 to SlotNotFoundError', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { code: 'P0002', message: 'slot not found' },
      });
      await expect(bookSlot('s1', 'topic words')).rejects.toBeInstanceOf(SlotNotFoundError);
    });
  });

  describe('cancelBooking', () => {
    it('passes p_slot_id', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: null });
      await cancelBooking('s1');
      expect(supabase.rpc).toHaveBeenCalledWith('cancel_booking', { p_slot_id: 's1' });
    });

    it('maps 42501 to OfficeHoursForbiddenError', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { code: '42501', message: 'only host or booker can cancel' },
      });
      await expect(cancelBooking('s1')).rejects.toBeInstanceOf(OfficeHoursForbiddenError);
    });
  });

  describe('listMyBookings', () => {
    it('maps rows', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: [
          {
            slot_id: 's1',
            host_id: 'h1',
            host_handle: 'alice',
            host_name: 'Alice',
            host_photo_url: null,
            starts_at: '2026-06-09T14:00:00Z',
            ends_at: '2026-06-09T14:30:00Z',
            topic: 'first chat',
            meeting_proposal_id: 'p1',
          },
        ],
        error: null,
      });
      const rows = await listMyBookings();
      expect(supabase.rpc).toHaveBeenCalledWith('my_bookings', {});
      expect(rows[0]).toEqual({
        slotId: 's1',
        hostId: 'h1',
        hostHandle: 'alice',
        hostName: 'Alice',
        hostPhotoUrl: null,
        startsAt: '2026-06-09T14:00:00Z',
        endsAt: '2026-06-09T14:30:00Z',
        topic: 'first chat',
        meetingProposalId: 'p1',
      });
    });
  });
});
