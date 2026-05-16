import {
  HandleSchema,
  NameSchema,
  HeadlineSchema,
  BioSchema,
  GoalTextSchema,
  RolesSchema,
  GoalTypeSchema,
} from '~/features/profile/schemas';

describe('profile schemas', () => {
  describe('HandleSchema', () => {
    it('accepts valid handles', () => {
      expect(HandleSchema.safeParse('a').success).toBe(true);
      expect(HandleSchema.safeParse('abc').success).toBe(true);
      expect(HandleSchema.safeParse('alice').success).toBe(true);
      expect(HandleSchema.safeParse('alice-bob-99').success).toBe(true);
    });
    it('rejects 2-char handles (matches DB constraint)', () => {
      expect(HandleSchema.safeParse('a1').success).toBe(false);
      expect(HandleSchema.safeParse('ab').success).toBe(false);
    });
    it('rejects uppercase, leading hyphen, trailing hyphen, too short', () => {
      expect(HandleSchema.safeParse('Alice').success).toBe(false);
      expect(HandleSchema.safeParse('-alice').success).toBe(false);
      expect(HandleSchema.safeParse('alice-').success).toBe(false);
      expect(HandleSchema.safeParse('').success).toBe(false);
    });
  });
  describe('NameSchema', () => {
    it('trims and requires 1-80 chars', () => {
      expect(NameSchema.safeParse('  Ahmad  ').data).toBe('Ahmad');
      expect(NameSchema.safeParse('').success).toBe(false);
      expect(NameSchema.safeParse('x'.repeat(81)).success).toBe(false);
    });
  });
  describe('HeadlineSchema', () => {
    it('requires 5-120 when set or allows empty/optional', () => {
      expect(HeadlineSchema.safeParse('short').success).toBe(true);
      expect(HeadlineSchema.safeParse('').success).toBe(true);
      expect(HeadlineSchema.safeParse('hi').success).toBe(false);
      expect(HeadlineSchema.safeParse('x'.repeat(121)).success).toBe(false);
    });
  });
  describe('BioSchema', () => {
    it('requires 10-1000 when set or allows empty', () => {
      expect(BioSchema.safeParse('').success).toBe(true);
      expect(BioSchema.safeParse('x'.repeat(10)).success).toBe(true);
      expect(BioSchema.safeParse('short').success).toBe(false);
      expect(BioSchema.safeParse('x'.repeat(1001)).success).toBe(false);
    });
  });
  describe('GoalTextSchema', () => {
    it('requires 10-280 chars', () => {
      expect(GoalTextSchema.safeParse('').success).toBe(false);
      expect(GoalTextSchema.safeParse('x'.repeat(10)).success).toBe(true);
      expect(GoalTextSchema.safeParse('x'.repeat(281)).success).toBe(false);
    });
  });
  describe('RolesSchema', () => {
    it('requires at least 1 role', () => {
      expect(RolesSchema.safeParse(['founder']).success).toBe(true);
      expect(RolesSchema.safeParse([]).success).toBe(false);
      expect(RolesSchema.safeParse(['unknown']).success).toBe(false);
    });
  });
  describe('GoalTypeSchema', () => {
    it('accepts only known enum values', () => {
      expect(GoalTypeSchema.safeParse('hire').success).toBe(true);
      expect(GoalTypeSchema.safeParse('xyz').success).toBe(false);
    });
  });
});
