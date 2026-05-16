import { IntroNoteSchema } from '~/features/intros/schemas';

describe('IntroNoteSchema', () => {
  it('accepts a 80-400 char note', () => {
    expect(IntroNoteSchema.safeParse('x'.repeat(80)).success).toBe(true);
    expect(IntroNoteSchema.safeParse('x'.repeat(400)).success).toBe(true);
  });
  it('rejects shorter than 80', () => {
    expect(IntroNoteSchema.safeParse('x'.repeat(79)).success).toBe(false);
  });
  it('rejects longer than 400', () => {
    expect(IntroNoteSchema.safeParse('x'.repeat(401)).success).toBe(false);
  });
  it('trims whitespace before counting', () => {
    expect(IntroNoteSchema.safeParse('  ' + 'x'.repeat(80) + '  ').success).toBe(true);
    expect(IntroNoteSchema.safeParse('  ' + 'x'.repeat(78) + '  ').success).toBe(false);
  });
});
