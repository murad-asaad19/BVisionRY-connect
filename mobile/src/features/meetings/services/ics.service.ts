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

/**
 * RFC 5545 §3.1 line folding: physical lines MUST be ≤75 octets (UTF-8 bytes,
 * not characters). Continuation lines start with CRLF + a single whitespace
 * (which itself counts toward the next chunk's octet budget).
 *
 * We accumulate one byte at a time so multibyte characters (UTF-8 sequences
 * up to 4 bytes) never get split across a fold boundary.
 */
export function foldLine(line: string): string {
  const encoder = new TextEncoder();
  // Fast path: single-byte ASCII lines under the limit don't need folding.
  if (line.length <= 75 && encoder.encode(line).length <= 75) return line;

  const chunks: string[] = [];
  let buf = '';
  let bufBytes = 0;
  // First chunk allows 75 octets; continuations allow 74 (the leading space
  // burns one octet of the 75-octet budget on every continuation line).
  let limit = 75;

  for (const ch of line) {
    const chBytes = encoder.encode(ch).length;
    if (bufBytes + chBytes > limit) {
      chunks.push(buf);
      buf = ch;
      bufBytes = chBytes;
      limit = 74; // continuation lines: 75 - 1 (leading space)
    } else {
      buf += ch;
      bufBytes += chBytes;
    }
  }
  if (buf.length > 0) chunks.push(buf);
  return chunks.join('\r\n ');
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
  const stamp = formatICSDate(new Date().toISOString());

  const rawLines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//BVisionRY Connect//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'BEGIN:VEVENT',
    `UID:meeting-${opts.meetingId}@bvisionry.com`,
    'SEQUENCE:0',
    `DTSTAMP:${stamp}`,
    `LAST-MODIFIED:${stamp}`,
    `DTSTART:${formatICSDate(start.toISOString())}`,
    `DTEND:${formatICSDate(end.toISOString())}`,
    `SUMMARY:${escapeICS(opts.summary)}`,
    'STATUS:CONFIRMED',
    opts.url ? `URL:${escapeICS(opts.url)}` : null,
    opts.description ? `DESCRIPTION:${escapeICS(opts.description)}` : null,
    'END:VEVENT',
    'END:VCALENDAR',
  ].filter((l): l is string => l !== null);

  return rawLines.map(foldLine).join('\r\n');
}

export const __test__ = { formatICSDate, escapeICS, foldLine };
