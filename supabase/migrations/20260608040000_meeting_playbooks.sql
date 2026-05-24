-- AI Meeting Playbooks
--
-- A "playbook" is a per-(meeting, viewer) Claude-generated briefing card that
-- helps the viewer prepare to meet the other party in a CONFIRMED meeting.
-- Each row caches one generation; cache hits are validated by:
--   * `generation_input_hash` — sha256 of the input we sent to Claude
--     (viewer profile fields, target profile fields, meeting topic). Any
--     drift to a relevant field invalidates the cache and forces regen.
--   * `generated_at` — soft 7-day TTL beyond which we regenerate even if
--     the hash is unchanged (covers prompt / model improvements).
--
-- Privacy boundary: this table is RLS-locked-shut. Direct table SELECT /
-- INSERT / UPDATE / DELETE from `authenticated` is denied. Reads happen
-- through `get_meeting_playbook(uuid)` (security definer, filters by
-- `viewer_id = auth.uid()` AND verifies the caller is a meeting
-- participant). Writes happen exclusively from the `meeting-playbook`
-- edge function via the service-role key, which authenticates the caller
-- by JWT before bypassing RLS.
--
-- The (meeting_id, viewer_id) primary key means each meeting has at most
-- two rows after both attendees view it. Cascade delete from
-- meeting_proposals scrubs both, so when a meeting is deleted the
-- generated content goes too.

create table public.meeting_playbooks (
  meeting_id uuid not null references public.meeting_proposals(id) on delete cascade,
  viewer_id uuid not null references public.profiles(id) on delete cascade,
  target_id uuid not null references public.profiles(id) on delete cascade,
  summary text not null,
  shared_interests text[] not null default '{}',
  conversation_starters text[] not null default '{}',
  do_notes text[] not null default '{}',
  dont_notes text[] not null default '{}',
  generated_at timestamptz not null default now(),
  generation_input_hash text not null,
  primary key (meeting_id, viewer_id)
);

create index meeting_playbooks_viewer_idx
  on public.meeting_playbooks (viewer_id, generated_at desc);

alter table public.meeting_playbooks enable row level security;

-- Reads via security-definer RPC; writes via edge-function (using service-role
-- key); table policies block direct access from anon/authenticated clients.
create policy "meeting_playbooks_no_direct_access"
  on public.meeting_playbooks for all to authenticated
  using (false)
  with check (false);

-- Returns the cached playbook row for the calling viewer of this meeting.
--
-- Returns zero rows when:
--   * the caller is not a participant in the meeting (silent — don't leak
--     existence to non-participants), or
--   * no playbook has been generated for this (meeting, caller) pair yet.
--
-- The edge function calls this AFTER generating to return the canonical
-- shape; the mobile client calls it directly on mount to decide whether
-- to invoke the (more expensive) edge function.
create or replace function public.get_meeting_playbook(p_meeting_id uuid)
returns table (
  summary text,
  shared_interests text[],
  conversation_starters text[],
  do_notes text[],
  dont_notes text[],
  generated_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  -- Participant check: meetings are tied to conversations, and the
  -- conversation row carries the two participant ids. Treat non-participant
  -- callers identically to "no row exists" — silent empty.
  if not exists (
    select 1
      from public.meeting_proposals m
      join public.conversations c on c.id = m.conversation_id
     where m.id = p_meeting_id
       and (c.participant_a_id = v_user or c.participant_b_id = v_user)
  ) then
    return;
  end if;
  return query
    select p.summary, p.shared_interests, p.conversation_starters,
           p.do_notes, p.dont_notes, p.generated_at
      from public.meeting_playbooks p
     where p.meeting_id = p_meeting_id
       and p.viewer_id = v_user;
end;
$$;

grant execute on function public.get_meeting_playbook(uuid) to authenticated;
