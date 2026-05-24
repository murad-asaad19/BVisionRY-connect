import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';
import type { CreateOpportunityInput } from '~/features/opportunities/schemas';

/**
 * Service wrappers around the Opportunities RPCs declared in
 * supabase/migrations/20260608020000_opportunities.sql. All RPCs are
 * SECURITY DEFINER and granted to `authenticated` only.
 *
 * `types.gen.ts` is regenerated at the end of the feature batch
 * (Task 7); until then we cast through `unknown` to local types so the
 * rest of the codebase stays strictly typed.
 */

export type RoleKind = Database['public']['Enums']['role_kind'];

export type OpportunityKind =
  | 'hiring'
  | 'seeking_role'
  | 'fundraising'
  | 'investing'
  | 'cofounder'
  | 'advising'
  | 'seeking_advisor'
  | 'collaboration';

export type OpportunityStatus = 'open' | 'closed' | 'archived';

export type OpportunityFeedItem = {
  id: string;
  authorId: string;
  kind: OpportunityKind;
  title: string;
  body: string;
  tags: string[];
  locationCity: string | null;
  locationCountry: string | null;
  remoteOk: boolean;
  expiresAt: string | null;
  createdAt: string;
  authorHandle: string;
  authorName: string;
  authorPhotoUrl: string | null;
  authorPrimaryRole: RoleKind | null;
  interestedCount: number;
};

export type MyOpportunityItem = {
  id: string;
  authorId: string;
  kind: OpportunityKind;
  title: string;
  body: string;
  tags: string[];
  locationCity: string | null;
  locationCountry: string | null;
  remoteOk: boolean;
  status: OpportunityStatus;
  expiresAt: string | null;
  createdAt: string;
  closedAt: string | null;
  interestedCount: number;
};

export type OpportunityDetail = MyOpportunityItem & {
  authorHandle: string;
  authorName: string;
  authorPhotoUrl: string | null;
  authorPrimaryRole: RoleKind | null;
  viewerHasExpressedInterest: boolean;
};

export type InterestedUser = {
  userId: string;
  handle: string;
  name: string;
  photoUrl: string | null;
  primaryRole: RoleKind | null;
  note: string | null;
  createdAt: string;
};

// =============================================================================
// Typed error hierarchy — UI can branch on `instanceof` and surface i18n'd
// copy without sniffing raw Postgres messages.
// =============================================================================
export class OpportunityError extends Error {
  readonly code: string;
  constructor(code: string, message: string) {
    super(message);
    this.code = code;
    this.name = 'OpportunityError';
  }
}
export class OpportunityValidationError extends OpportunityError {
  constructor(message = 'invalid opportunity input') {
    super('validation', message);
    this.name = 'OpportunityValidationError';
  }
}
export class OpportunityForbiddenError extends OpportunityError {
  constructor(message = 'forbidden') {
    super('forbidden', message);
    this.name = 'OpportunityForbiddenError';
  }
}
export class OpportunityClosedError extends OpportunityError {
  constructor(message = 'opportunity is not open') {
    super('closed', message);
    this.name = 'OpportunityClosedError';
  }
}
export class OpportunityNotFoundError extends OpportunityError {
  constructor(message = 'opportunity not found') {
    super('not_found', message);
    this.name = 'OpportunityNotFoundError';
  }
}

function mapError(err: { code?: string | null; message?: string | null }): OpportunityError {
  const code = err.code ?? 'unknown';
  const msg = err.message ?? '';
  if (code === '42501') return new OpportunityForbiddenError(msg);
  if (code === 'P0002') return new OpportunityNotFoundError(msg);
  if (code === '22023') {
    if (/not open|expired/i.test(msg)) return new OpportunityClosedError(msg);
    return new OpportunityValidationError(msg);
  }
  return new OpportunityError(code, msg);
}

// =============================================================================
// Row mappers — snake_case (Postgres) → camelCase (TS).
// =============================================================================
type FeedRow = {
  id: string;
  author_id: string;
  kind: OpportunityKind;
  title: string;
  body: string;
  tags: string[];
  location_city: string | null;
  location_country: string | null;
  remote_ok: boolean;
  expires_at: string | null;
  created_at: string;
  author_handle: string;
  author_name: string;
  author_photo_url: string | null;
  author_primary_role: RoleKind | null;
  interested_count: number;
};

type DetailRow = FeedRow & {
  status: OpportunityStatus;
  closed_at: string | null;
  viewer_has_expressed_interest: boolean;
};

type MyRow = {
  id: string;
  author_id: string;
  kind: OpportunityKind;
  title: string;
  body: string;
  tags: string[];
  location_city: string | null;
  location_country: string | null;
  remote_ok: boolean;
  status: OpportunityStatus;
  expires_at: string | null;
  created_at: string;
  closed_at: string | null;
  interested_count: number;
};

type InterestedRow = {
  user_id: string;
  handle: string;
  name: string;
  photo_url: string | null;
  primary_role: RoleKind | null;
  note: string | null;
  created_at: string;
};

function mapFeedRow(r: FeedRow): OpportunityFeedItem {
  return {
    id: r.id,
    authorId: r.author_id,
    kind: r.kind,
    title: r.title,
    body: r.body,
    tags: r.tags ?? [],
    locationCity: r.location_city,
    locationCountry: r.location_country,
    remoteOk: r.remote_ok,
    expiresAt: r.expires_at,
    createdAt: r.created_at,
    authorHandle: r.author_handle,
    authorName: r.author_name,
    authorPhotoUrl: r.author_photo_url,
    authorPrimaryRole: r.author_primary_role,
    interestedCount: r.interested_count,
  };
}

function mapMyRow(r: MyRow): MyOpportunityItem {
  return {
    id: r.id,
    authorId: r.author_id,
    kind: r.kind,
    title: r.title,
    body: r.body,
    tags: r.tags ?? [],
    locationCity: r.location_city,
    locationCountry: r.location_country,
    remoteOk: r.remote_ok,
    status: r.status,
    expiresAt: r.expires_at,
    createdAt: r.created_at,
    closedAt: r.closed_at,
    interestedCount: r.interested_count,
  };
}

function mapDetailRow(r: DetailRow): OpportunityDetail {
  return {
    ...mapMyRow({
      id: r.id,
      author_id: r.author_id,
      kind: r.kind,
      title: r.title,
      body: r.body,
      tags: r.tags,
      location_city: r.location_city,
      location_country: r.location_country,
      remote_ok: r.remote_ok,
      status: r.status,
      expires_at: r.expires_at,
      created_at: r.created_at,
      closed_at: r.closed_at,
      interested_count: r.interested_count,
    }),
    authorHandle: r.author_handle,
    authorName: r.author_name,
    authorPhotoUrl: r.author_photo_url,
    authorPrimaryRole: r.author_primary_role,
    viewerHasExpressedInterest: r.viewer_has_expressed_interest,
  };
}

function mapInterestedRow(r: InterestedRow): InterestedUser {
  return {
    userId: r.user_id,
    handle: r.handle,
    name: r.name,
    photoUrl: r.photo_url,
    primaryRole: r.primary_role,
    note: r.note,
    createdAt: r.created_at,
  };
}

// =============================================================================
// RPCs.
// =============================================================================
// IMPORTANT: must use `.bind(supabase)` — without it the call site sees
// `this === undefined` and supabase-js throws "Cannot read properties of
// undefined (reading 'rest')". A bare `const rpc = supabase.rpc` aliases the
// method but drops the receiver.
const rpc = supabase.rpc.bind(supabase) as unknown as <T, A extends Record<string, unknown>>(
  fn: string,
  args: A
) => Promise<{ data: T | null; error: { code?: string | null; message?: string | null } | null }>;

export type ListOpportunitiesFilters = {
  kinds?: OpportunityKind[];
  remoteOnly?: boolean;
  search?: string;
  limit?: number;
  offset?: number;
};

export async function listOpportunities(
  filters: ListOpportunitiesFilters = {}
): Promise<OpportunityFeedItem[]> {
  const { data, error } = await rpc<FeedRow[], {
    p_kinds: OpportunityKind[] | null;
    p_remote_only: boolean;
    p_search: string | null;
    p_limit: number;
    p_offset: number;
  }>('list_opportunities', {
    p_kinds: filters.kinds && filters.kinds.length > 0 ? filters.kinds : null,
    p_remote_only: filters.remoteOnly ?? false,
    p_search: filters.search?.trim() ? filters.search.trim() : null,
    p_limit: filters.limit ?? 20,
    p_offset: filters.offset ?? 0,
  });
  if (error) throw mapError(error);
  return (data ?? []).map(mapFeedRow);
}

export async function getOpportunity(id: string): Promise<OpportunityDetail> {
  const { data, error } = await rpc<DetailRow[], { p_id: string }>('get_opportunity', {
    p_id: id,
  });
  if (error) throw mapError(error);
  const row = (data ?? [])[0];
  if (!row) throw new OpportunityNotFoundError();
  return mapDetailRow(row);
}

export async function createOpportunity(input: CreateOpportunityInput): Promise<string> {
  const { data, error } = await rpc<string, {
    p_kind: OpportunityKind;
    p_title: string;
    p_body: string;
    p_tags: string[];
    p_location_city: string | null;
    p_location_country: string | null;
    p_remote_ok: boolean;
    p_expires_at: string | null;
  }>('create_opportunity', {
    p_kind: input.kind,
    p_title: input.title,
    p_body: input.body,
    p_tags: input.tags ?? [],
    p_location_city: input.locationCity ?? null,
    p_location_country: input.locationCountry ?? null,
    p_remote_ok: input.remoteOk ?? false,
    p_expires_at: input.expiresAt ?? null,
  });
  if (error) throw mapError(error);
  if (!data) throw new OpportunityError('unknown', 'create_opportunity returned no id');
  return data;
}

export async function updateOpportunity(
  id: string,
  input: CreateOpportunityInput
): Promise<void> {
  const { error } = await rpc<void, {
    p_id: string;
    p_kind: OpportunityKind;
    p_title: string;
    p_body: string;
    p_tags: string[];
    p_location_city: string | null;
    p_location_country: string | null;
    p_remote_ok: boolean;
    p_expires_at: string | null;
  }>('update_opportunity', {
    p_id: id,
    p_kind: input.kind,
    p_title: input.title,
    p_body: input.body,
    p_tags: input.tags ?? [],
    p_location_city: input.locationCity ?? null,
    p_location_country: input.locationCountry ?? null,
    p_remote_ok: input.remoteOk ?? false,
    p_expires_at: input.expiresAt ?? null,
  });
  if (error) throw mapError(error);
}

export async function closeOpportunity(id: string): Promise<void> {
  const { error } = await rpc<void, { p_id: string }>('close_opportunity', { p_id: id });
  if (error) throw mapError(error);
}

export async function expressInterest(opportunityId: string, note?: string): Promise<void> {
  const { error } = await rpc<void, { p_opportunity_id: string; p_note: string | null }>(
    'express_interest',
    {
      p_opportunity_id: opportunityId,
      p_note: note && note.trim() ? note.trim() : null,
    }
  );
  if (error) throw mapError(error);
}

export async function listMyOpportunities(): Promise<MyOpportunityItem[]> {
  const { data, error } = await rpc<MyRow[], Record<string, never>>(
    'list_my_opportunities',
    {} as Record<string, never>
  );
  if (error) throw mapError(error);
  return (data ?? []).map(mapMyRow);
}

export async function listInterested(opportunityId: string): Promise<InterestedUser[]> {
  const { data, error } = await rpc<InterestedRow[], { p_opportunity_id: string }>(
    'list_interested',
    { p_opportunity_id: opportunityId }
  );
  if (error) throw mapError(error);
  return (data ?? []).map(mapInterestedRow);
}
