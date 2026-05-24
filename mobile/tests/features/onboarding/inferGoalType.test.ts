import { inferGoalType } from '~/features/onboarding/components/GoalStep';

/**
 * Table-driven coverage of the keyword heuristic, including the two
 * branch-ordering cases the source comment calls out:
 *   - `invest` MUST run before `take_investment` (an investor talking about
 *     startups raising pre-seed is still an investor).
 *   - `find_advisor` MUST run before `advise` (someone looking for an advisor
 *     is not themselves advising).
 *
 * English + Spanish synonyms hit both the `\b…\b` ASCII path and the
 * `(?:^|\W)…(?:\W|$)` path used for accented / hyphenated Spanish words.
 */
describe('inferGoalType', () => {
  const cases: ReadonlyArray<{
    label: string;
    text: string;
    expected: ReturnType<typeof inferGoalType>;
  }> = [
    // ── English ──────────────────────────────────────────────────────────
    { label: 'EN invest', text: 'I write checks and lead seed rounds — actively investing', expected: 'invest' },
    { label: 'EN take_investment', text: 'Raising pre-seed for a healthtech idea', expected: 'take_investment' },
    { label: 'EN hire', text: 'Hiring a fractional designer next month', expected: 'hire' },
    { label: 'EN be_hired', text: 'Looking for a role at an early-stage startup', expected: 'be_hired' },
    { label: 'EN co_found', text: 'Searching for a technical co-founder', expected: 'co_found' },
    { label: 'EN find_advisor', text: 'I need an advisor with B2B sales experience', expected: 'find_advisor' },
    { label: 'EN advise', text: 'Open to advising fintech founders', expected: 'advise' },

    // ── Spanish (accented / hyphenated synonyms) ─────────────────────────
    { label: 'ES invest', text: 'Quiero invertir en startups latinas', expected: 'invest' },
    { label: 'ES take_investment', text: 'Necesitamos levantar capital para nuestra ronda pre-semilla', expected: 'take_investment' },
    { label: 'ES hire', text: 'Estamos contratando ingenieros senior', expected: 'hire' },
    { label: 'ES be_hired', text: 'Estoy buscando trabajo como diseñador', expected: 'be_hired' },
    { label: 'ES co_found', text: 'Busco co-fundador técnico para mi proyecto', expected: 'co_found' },
    { label: 'ES find_advisor', text: 'Busco asesor con experiencia en ventas B2B', expected: 'find_advisor' },
    { label: 'ES advise', text: 'Ofrezco mentoría a fundadores en etapa temprana', expected: 'advise' },

    // ── Ordering edge cases (source comment calls these out explicitly) ──
    {
      label: 'EN ordering: invest before take_investment',
      text: 'Looking to invest in startups raising pre-seed',
      expected: 'invest',
    },
    {
      label: 'EN ordering: find_advisor before advise',
      text: 'Need to find an advisor who can advise me on pricing',
      expected: 'find_advisor',
    },

    // ── Fallback ────────────────────────────────────────────────────────
    { label: 'fallback to peer_connect', text: 'Just here to meet interesting people', expected: 'peer_connect' },
  ];

  it.each(cases)('$label → $expected', ({ text, expected }) => {
    expect(inferGoalType(text)).toBe(expected);
  });
});
