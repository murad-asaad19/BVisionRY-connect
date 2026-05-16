import {
  SlotsSchema,
  DurationSchema,
  MeetingUrlSchema,
  FeedbackNoteSchema,
  RatingSchema,
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
  describe('FeedbackNoteSchema', () => {
    it('accepts empty or up to 1000 chars', () => {
      expect(FeedbackNoteSchema.safeParse('').success).toBe(true);
      expect(FeedbackNoteSchema.safeParse('x'.repeat(1000)).success).toBe(true);
      expect(FeedbackNoteSchema.safeParse('x'.repeat(1001)).success).toBe(false);
    });
  });
  describe('RatingSchema', () => {
    it('accepts the three values', () => {
      expect(RatingSchema.safeParse('positive').success).toBe(true);
      expect(RatingSchema.safeParse('neutral').success).toBe(true);
      expect(RatingSchema.safeParse('negative').success).toBe(true);
      expect(RatingSchema.safeParse('great').success).toBe(false);
    });
  });
});
