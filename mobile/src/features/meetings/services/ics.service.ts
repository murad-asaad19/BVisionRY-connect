/**
 * Generate an RFC 5545 VCALENDAR/VEVENT body for a confirmed meeting.
 * All times are emitted in UTC (`Z`-suffixed) so they're calendar-agnostic.
 */

function formatICSDate(iso: string): string {
  // ISO -> compact UTC: 2030-01-01T14:00:00.000Z -> 20300101T140000Z
  return new Date(iso)
    .toISOString()
    .replace(/[-:]/g, '')
    .replace(/\.\d{3}/, '');
}

function escapeICS(s: string): string {
  return s.replace(/\\/g, '\\\\').replace(/;/g, '\\;').replace(/,/g, '\\,').replace(/\n/g, '\\n');
}

export type GenerateICSOptions = {
  meetingId: string;
  startIso: string;
  durationMinutes: number;
  summary: string;
  url: string | null;
  description?: string;
};

export function generateICS(opts: GenerateICSOptions): string {
  const start = new Date(opts.startIso);
  const end = new Date(start.getTime() + opts.durationMinutes * 60_000);

  const lines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//BVisionRY Connect//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'BEGIN:VEVENT',
    `UID:meeting-${opts.meetingId}@bvisionry.example`,
    `DTSTAMP:${formatICSDate(new Date().toISOString())}`,
    `DTSTART:${formatICSDate(start.toISOString())}`,
    `DTEND:${formatICSDate(end.toISOString())}`,
    `SUMMARY:${escapeICS(opts.summary)}`,
    opts.url ? `URL:${escapeICS(opts.url)}` : null,
    opts.description ? `DESCRIPTION:${escapeICS(opts.description)}` : null,
    'END:VEVENT',
    'END:VCALENDAR',
  ].filter((l): l is string => l !== null);

  return lines.join('\r\n');
}

export const __test__ = { formatICSDate, escapeICS };
