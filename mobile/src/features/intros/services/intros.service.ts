import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';
import type { PostgrestError } from '@supabase/supabase-js';

export type IntroRow = Database['public']['Tables']['intros']['Row'] & {
  /** Stamped by decline_intro RPC in migration 20260606080000. Generated types are stale. */
  declined_at?: string | null;
};
export type IntroState = Database['public']['Enums']['intro_state'];

const PAGE_SIZE = 20;
// Far-future sentinel for cursor pagination — newer than any plausible created_at.
export const MAX_CURSOR_ISO = new Date(8640000000000000).toISOString();

// =============================================================================
// Typed errors — UI can branch on `instanceof` and surface i18n'd copy without
// regex-sniffing raw Postgres messages.
// =============================================================================
export class IntroError extends Error {
  readonly code: string;
  constructor(code: string, message: string) {
    super(message);
    this.code = code;
    this.name = 'IntroError';
  }
}
export class IntroDuplicateError extends IntroError {
  constructor(message = 'duplicate intro') {
    super('duplicate', message);
    this.name = 'IntroDuplicateError';
  }
}
export class IntroCooldownError extends IntroError {
  constructor(message = 'cooldown active') {
    super('cooldown', message);
    this.name = 'IntroCooldownError';
  }
}
export class IntroRateLimitError extends IntroError {
  constructor(message = 'daily cap reached') {
    super('daily_cap', message);
    this.name = 'IntroRateLimitError';
  }
}
export class IntroExpiredError extends IntroError {
  constructor(message = 'intro has expired') {
    super('expired', message);
    this.name = 'IntroExpiredError';
  }
}

function mapPostgrestError(err: PostgrestError): IntroError {
  const msg = err.message ?? '';
  // 23505 unique_violation — only intros_active_pair_uq is unique on (sender, recipient).
  if (err.code === '23505' || /intros_active_pair_uq|duplicate key/i.test(msg)) {
    return new IntroDuplicateError(msg);
  }
  // send_intro raises P0001 with distinct messages for cooldown vs cap.
  if (err.code === 'P0001') {
    if (/cooldown/i.test(msg)) return new IntroCooldownError(msg);
    if (/daily cap|cap reached/i.test(msg)) return new IntroRateLimitError(msg);
  }
  // accept_intro raises 22023 'intro has expired'.
  if (err.code === '22023' && /expired/i.test(msg)) {
    return new IntroExpiredError(msg);
  }
  return new IntroError(err.code ?? 'unknown', msg);
}

export async function sendIntro(params: { recipientId: string; note: string }): Promise<IntroRow> {
  const { data, error } = await supabase.rpc('send_intro', {
    p_recipient_id: params.recipientId,
    p_note: params.note,
  });
  if (error) throw mapPostgrestError(error);
  return data as IntroRow;
}

export async function acceptIntro(introId: string): Promise<IntroRow> {
  const { data, error } = await supabase.rpc('accept_intro', { p_intro_id: introId });
  if (error) throw mapPostgrestError(error);
  return data as IntroRow;
}

export async function declineIntro(introId: string): Promise<IntroRow> {
  const { data, error } = await supabase.rpc('decline_intro', { p_intro_id: introId });
  if (error) throw mapPostgrestError(error);
  return data as IntroRow;
}

export async function fetchInboxPage(params: {
  userId: string;
  cursor: string | null;
  pageSize?: number;
}): Promise<{ rows: IntroRow[]; nextCursor: string | null }> {
  const limit = params.pageSize ?? PAGE_SIZE;
  const cursor = params.cursor ?? MAX_CURSOR_ISO;
  const { data, error } = await supabase
    .from('intros')
    .select('*')
    .eq('recipient_id', params.userId)
    // 'connected' is the post-accept state (slice 5 transitions delivered → connected,
    // skipping 'accepted'). Including all three keeps accepted intros visible in inbox.
    .in('state', ['delivered', 'accepted', 'connected'])
    .gt('expires_at', new Date().toISOString())
    .lt('created_at', cursor)
    .order('created_at', { ascending: false })
    .limit(limit);
  if (error) throw mapPostgrestError(error);
  const rows = (data ?? []) as IntroRow[];
  const nextCursor = rows.length === limit ? rows[rows.length - 1]!.created_at : null;
  return { rows, nextCursor };
}

export async function fetchSentPage(params: {
  userId: string;
  cursor: string | null;
  pageSize?: number;
}): Promise<{ rows: IntroRow[]; nextCursor: string | null }> {
  const limit = params.pageSize ?? PAGE_SIZE;
  const cursor = params.cursor ?? MAX_CURSOR_ISO;
  const { data, error } = await supabase
    .from('intros')
    .select('*')
    .eq('sender_id', params.userId)
    .lt('created_at', cursor)
    .order('created_at', { ascending: false })
    .limit(limit);
  if (error) throw mapPostgrestError(error);
  const rows = (data ?? []) as IntroRow[];
  const nextCursor = rows.length === limit ? rows[rows.length - 1]!.created_at : null;
  return { rows, nextCursor };
}

export async function fetchIntroById(id: string): Promise<IntroRow | null> {
  const { data, error } = await supabase.from('intros').select('*').eq('id', id).single();
  if (error) {
    if (error.code === 'PGRST116') return null;
    throw mapPostgrestError(error);
  }
  return data as IntroRow;
}

/** Server-truth count of intros received today by the current user. */
export async function fetchIntrosTodayCount(): Promise<number> {
  // RPC is added in 20260606080000_intros_fixes.sql; types.gen.ts has not been regenerated.
  const { data, error } = await (supabase.rpc as any)('intros_today_count');
  if (error) throw mapPostgrestError(error);
  return typeof data === 'number' ? data : 0;
}
