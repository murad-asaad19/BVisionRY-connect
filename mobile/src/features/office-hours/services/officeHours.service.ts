import { supabase } from '~/lib/supabase/client';
import type { OfficeHoursSettingsInput, Window } from '~/features/office-hours/schemas';

/**
 * Wrappers around the office-hours RPCs declared in
 * supabase/migrations/20260608030000_office_hours.sql. All RPCs are
 * SECURITY DEFINER and granted to `authenticated` only.
 *
 * `types.gen.ts` is regenerated at the end of the feature batch (Task 7);
 * until then we cast through `unknown` to local types so the rest of the
 * codebase stays strictly typed.
 */

// =============================================================================
// Public shapes (camelCase on the way out).
// =============================================================================
export type OfficeHoursSettings = {
  userId: string;
  enabled: boolean;
  windows: Window[];
  slotDurationMinutes: 15 | 30 | 45 | 60;
  maxBookingsPerWeek: number;
  bufferMinutes: number;
  meetingLinkTemplate: string | null;
  notesTemplate: string | null;
  updatedAt: string;
};

export type UpcomingSlot = {
  id: string;
  startsAt: string;
  endsAt: string;
  hostNotesTemplate: string | null;
};

export type MyBooking = {
  slotId: string;
  hostId: string;
  hostHandle: string;
  hostName: string;
  hostPhotoUrl: string | null;
  startsAt: string;
  endsAt: string;
  topic: string | null;
  meetingProposalId: string | null;
};

// =============================================================================
// Error hierarchy. UI branches on `instanceof`.
// =============================================================================
export class OfficeHoursError extends Error {
  readonly code: string;
  constructor(code: string, message: string) {
    super(message);
    this.code = code;
    this.name = 'OfficeHoursError';
  }
}
export class OfficeHoursValidationError extends OfficeHoursError {
  constructor(message = 'invalid office-hours input') {
    super('validation', message);
    this.name = 'OfficeHoursValidationError';
  }
}
export class OfficeHoursForbiddenError extends OfficeHoursError {
  constructor(message = 'forbidden') {
    super('forbidden', message);
    this.name = 'OfficeHoursForbiddenError';
  }
}
export class SlotUnavailableError extends OfficeHoursError {
  constructor(message = 'slot is no longer available') {
    super('slot_unavailable', message);
    this.name = 'SlotUnavailableError';
  }
}
export class MaxBookingsReachedError extends OfficeHoursError {
  constructor(message = 'max bookings per week reached') {
    super('max_bookings_reached', message);
    this.name = 'MaxBookingsReachedError';
  }
}
export class SlotNotFoundError extends OfficeHoursError {
  constructor(message = 'slot not found') {
    super('not_found', message);
    this.name = 'SlotNotFoundError';
  }
}

function mapError(err: { code?: string | null; message?: string | null }): OfficeHoursError {
  const code = err.code ?? 'unknown';
  const msg = err.message ?? '';
  if (code === '42501') return new OfficeHoursForbiddenError(msg);
  if (code === 'P0002') return new SlotNotFoundError(msg);
  if (code === '22023') {
    if (/max bookings/i.test(msg)) return new MaxBookingsReachedError(msg);
    if (/slot is not open|too close|no longer accepting|cannot book/i.test(msg))
      return new SlotUnavailableError(msg);
    return new OfficeHoursValidationError(msg);
  }
  return new OfficeHoursError(code, msg);
}

// =============================================================================
// Row mappers.
// =============================================================================
type SettingsRow = {
  user_id: string;
  enabled: boolean;
  // server stores windows in snake_case shape.
  windows:
    | Array<{
        weekday: number;
        start_minute: number;
        end_minute: number;
        timezone: string;
      }>
    | null;
  slot_duration_minutes: number;
  max_bookings_per_week: number;
  buffer_minutes: number;
  meeting_link_template: string | null;
  notes_template: string | null;
  updated_at: string;
};

function mapSettings(r: SettingsRow): OfficeHoursSettings {
  return {
    userId: r.user_id,
    enabled: r.enabled,
    windows: (r.windows ?? []).map((w) => ({
      weekday: w.weekday,
      startMinute: w.start_minute,
      endMinute: w.end_minute,
      timezone: w.timezone,
    })),
    slotDurationMinutes: r.slot_duration_minutes as 15 | 30 | 45 | 60,
    maxBookingsPerWeek: r.max_bookings_per_week,
    bufferMinutes: r.buffer_minutes,
    meetingLinkTemplate: r.meeting_link_template,
    notesTemplate: r.notes_template,
    updatedAt: r.updated_at,
  };
}

type SlotRow = {
  id: string;
  starts_at: string;
  ends_at: string;
  host_settings_notes_template: string | null;
};

function mapSlot(r: SlotRow): UpcomingSlot {
  return {
    id: r.id,
    startsAt: r.starts_at,
    endsAt: r.ends_at,
    hostNotesTemplate: r.host_settings_notes_template,
  };
}

type MyBookingRow = {
  slot_id: string;
  host_id: string;
  host_handle: string;
  host_name: string;
  host_photo_url: string | null;
  starts_at: string;
  ends_at: string;
  topic: string | null;
  meeting_proposal_id: string | null;
};

function mapMyBooking(r: MyBookingRow): MyBooking {
  return {
    slotId: r.slot_id,
    hostId: r.host_id,
    hostHandle: r.host_handle,
    hostName: r.host_name,
    hostPhotoUrl: r.host_photo_url,
    startsAt: r.starts_at,
    endsAt: r.ends_at,
    topic: r.topic,
    meetingProposalId: r.meeting_proposal_id,
  };
}

// =============================================================================
// RPCs.
// =============================================================================
// Must `.bind(supabase)` — supabase-js's `rpc` reads `this.rest` internally,
// so an unbound alias raises "Cannot read properties of undefined (reading
// 'rest')" at the first call. Same issue as opportunities.service.ts.
const rpc = supabase.rpc.bind(supabase) as unknown as <T, A extends Record<string, unknown>>(
  fn: string,
  args: A
) => Promise<{ data: T | null; error: { code?: string | null; message?: string | null } | null }>;

export async function getMyOfficeHoursSettings(): Promise<OfficeHoursSettings> {
  const { data, error } = await rpc<SettingsRow, Record<string, never>>(
    'my_office_hours_settings',
    {} as Record<string, never>
  );
  if (error) throw mapError(error);
  if (!data) throw new OfficeHoursError('unknown', 'my_office_hours_settings returned no row');
  return mapSettings(data);
}

export async function setOfficeHours(input: OfficeHoursSettingsInput): Promise<OfficeHoursSettings> {
  const windowsServer = input.windows.map((w) => ({
    weekday: w.weekday,
    start_minute: w.startMinute,
    end_minute: w.endMinute,
    timezone: w.timezone,
  }));
  const { data, error } = await rpc<SettingsRow, {
    p_enabled: boolean;
    p_windows: typeof windowsServer;
    p_slot_duration_minutes: number;
    p_max_bookings_per_week: number;
    p_buffer_minutes: number;
    p_meeting_link_template: string | null;
    p_notes_template: string | null;
  }>('set_office_hours', {
    p_enabled: input.enabled,
    p_windows: windowsServer,
    p_slot_duration_minutes: input.slotDurationMinutes,
    p_max_bookings_per_week: input.maxBookingsPerWeek,
    p_buffer_minutes: input.bufferMinutes,
    p_meeting_link_template: input.meetingLinkTemplate ?? null,
    p_notes_template: input.notesTemplate ?? null,
  });
  if (error) throw mapError(error);
  if (!data) throw new OfficeHoursError('unknown', 'set_office_hours returned no row');
  return mapSettings(data);
}

export async function listUpcomingSlots(hostId: string): Promise<UpcomingSlot[]> {
  const { data, error } = await rpc<SlotRow[], { p_host: string }>('list_upcoming_slots', {
    p_host: hostId,
  });
  if (error) throw mapError(error);
  return (data ?? []).map(mapSlot);
}

export async function bookSlot(slotId: string, topic: string): Promise<string> {
  const { data, error } = await rpc<string, { p_slot_id: string; p_topic: string }>('book_slot', {
    p_slot_id: slotId,
    p_topic: topic,
  });
  if (error) throw mapError(error);
  if (!data) throw new OfficeHoursError('unknown', 'book_slot returned no proposal id');
  return data;
}

export async function cancelBooking(slotId: string): Promise<void> {
  const { error } = await rpc<void, { p_slot_id: string }>('cancel_booking', {
    p_slot_id: slotId,
  });
  if (error) throw mapError(error);
}

export async function listMyBookings(): Promise<MyBooking[]> {
  const { data, error } = await rpc<MyBookingRow[], Record<string, never>>(
    'my_bookings',
    {} as Record<string, never>
  );
  if (error) throw mapError(error);
  return (data ?? []).map(mapMyBooking);
}
