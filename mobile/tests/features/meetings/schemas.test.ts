import {
  SlotsSchema,
  DurationSchema,
  MeetingUrlSchema,
  OutcomeSchema,
} from '~/features/meetings/schemas';

describe('meetings schemas', () => {
  describe('SlotsSchema', () => {
    it('accepts 1-3 future ISO timestamps', () => {
      const future = new Date(Date.now() + 86400_000).toISOString();
      expect(SlotsSchema.safeParse([future]).success).toBe(true);
      expect(SlotsSchema.safeParse([future, future, future]).success).toBe(true);
    });
    it('rejects 0 slots and 4 slots', () => {
      expect(SlotsSchema.safeParse([]).success).toBe(false);
      const f = new Date(Date.now() + 86400_000).toISOString();
      expect(SlotsSchema.safeParse([f, f, f, f]).success).toBe(false);
    });
    it('rejects past timestamps', () => {
      const past = new Date(Date.now() - 86400_000).toISOString();
      expect(SlotsSchema.safeParse([past]).success).toBe(false);
    });
  });
  describe('DurationSchema', () => {
    it('accepts 15-240', () => {
      expect(DurationSchema.safeParse(15).success).toBe(true);
      expect(DurationSchema.safeParse(240).success).toBe(true);
    });
    it('rejects out of range', () => {
      expect(DurationSchema.safeParse(14).success).toBe(false);
      expect(DurationSchema.safeParse(241).success).toBe(false);
    });
  });
  describe('MeetingUrlSchema', () => {
    it('accepts https urls or empty', () => {
      expect(MeetingUrlSchema.safeParse('https://meet.foo/abc').success).toBe(true);
      expect(MeetingUrlSchema.safeParse('').success).toBe(true);
    });
    it('rejects http and non-url', () => {
      expect(MeetingUrlSchema.safeParse('http://insecure').success).toBe(false);
      expect(MeetingUrlSchema.safeParse('not a url').success).toBe(false);
    });
  });
  describe('OutcomeSchema', () => {
    it('accepts useful / not_useful / no_show', () => {
      expect(OutcomeSchema.safeParse('useful').success).toBe(true);
      expect(OutcomeSchema.safeParse('not_useful').success).toBe(true);
      expect(OutcomeSchema.safeParse('no_show').success).toBe(true);
    });
    it('rejects unknown values', () => {
      expect(OutcomeSchema.safeParse('positive').success).toBe(false);
      expect(OutcomeSchema.safeParse('').success).toBe(false);
    });
  });
});
