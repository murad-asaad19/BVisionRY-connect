import { generateICS, __test__ } from '~/features/meetings/services/ics.service';

describe('ics.service', () => {
  describe('formatICSDate', () => {
    it('formats ISO date to compact UTC form', () => {
      expect(__test__.formatICSDate('2030-01-01T14:00:00.000Z')).toBe('20300101T140000Z');
      expect(__test__.formatICSDate('2030-12-31T23:59:00Z')).toBe('20301231T235900Z');
    });
  });

  describe('escapeICS', () => {
    it('escapes special characters per RFC 5545', () => {
      expect(__test__.escapeICS('a;b,c\nd\\e')).toBe('a\\;b\\,c\\nd\\\\e');
    });
  });

  describe('generateICS', () => {
    it('emits VCALENDAR/VEVENT with DTSTART/DTEND and SUMMARY in UTC', () => {
      const ics = generateICS({
        meetingId: 'mp1',
        startIso: '2030-01-01T14:00:00.000Z',
        durationMinutes: 30,
        summary: 'Meeting with @alice',
        url: 'https://meet.google.com/abc-defg-hij',
      });

      expect(ics).toContain('BEGIN:VCALENDAR');
      expect(ics).toContain('VERSION:2.0');
      expect(ics).toContain('BEGIN:VEVENT');
      expect(ics).toContain('UID:meeting-mp1@bvisionry.com');
      expect(ics).toContain('SEQUENCE:0');
      expect(ics).toContain('STATUS:CONFIRMED');
      expect(ics).toMatch(/LAST-MODIFIED:\d{8}T\d{6}Z/);
      expect(ics).toContain('DTSTART:20300101T140000Z');
      expect(ics).toContain('DTEND:20300101T143000Z');
      expect(ics).toContain('SUMMARY:Meeting with @alice');
      expect(ics).toContain('URL:https://meet.google.com/abc-defg-hij');
      expect(ics).toContain('END:VEVENT');
      expect(ics).toContain('END:VCALENDAR');
      // CRLF line endings per spec
      expect(ics).toContain('\r\n');
    });

    it('computes DTEND from durationMinutes correctly', () => {
      const ics = generateICS({
        meetingId: 'mp2',
        startIso: '2030-06-15T09:00:00.000Z',
        durationMinutes: 90,
        summary: 'Sync',
        url: null,
      });
      expect(ics).toContain('DTSTART:20300615T090000Z');
      expect(ics).toContain('DTEND:20300615T103000Z');
    });

    it('omits URL line when url is null', () => {
      const ics = generateICS({
        meetingId: 'mp3',
        startIso: '2030-01-01T14:00:00.000Z',
        durationMinutes: 30,
        summary: 'Meeting',
        url: null,
      });
      expect(ics).not.toContain('URL:');
    });

    it('includes DESCRIPTION when provided', () => {
      const ics = generateICS({
        meetingId: 'mp4',
        startIso: '2030-01-01T14:00:00.000Z',
        durationMinutes: 30,
        summary: 'Meeting',
        url: null,
        description: 'Discuss roadmap',
      });
      expect(ics).toContain('DESCRIPTION:Discuss roadmap');
    });

    it('escapes commas/semicolons in summary', () => {
      const ics = generateICS({
        meetingId: 'mp5',
        startIso: '2030-01-01T14:00:00.000Z',
        durationMinutes: 30,
        summary: 'Meeting; with, alice',
        url: null,
      });
      expect(ics).toContain('SUMMARY:Meeting\\; with\\, alice');
    });

    it('folds long DESCRIPTION lines to ≤75 octets per RFC 5545 §3.1', () => {
      const longDescription = 'x'.repeat(200);
      const ics = generateICS({
        meetingId: 'mp6',
        startIso: '2030-01-01T14:00:00.000Z',
        durationMinutes: 30,
        summary: 'Meeting',
        url: null,
        description: longDescription,
      });
      // Every physical line must be ≤75 octets per the spec. Continuation
      // lines start with a leading space, which itself counts toward the
      // 75-byte budget — so checking each post-split line uniformly works.
      const encoder = new TextEncoder();
      for (const line of ics.split('\r\n')) {
        expect(encoder.encode(line).length).toBeLessThanOrEqual(75);
      }
    });
  });
});
