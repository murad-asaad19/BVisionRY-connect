-- Phase 2 meeting reviews: post-meeting prompt + 5-star reviews.
create table public.meeting_reviews (
  id              uuid primary key default gen_random_uuid(),
  meeting_id      uuid not null references public.meeting_proposals(id) on delete cascade,
  reviewer_id     uuid not null references public.profiles(id) on delete cascade,
  rating          int not null check (rating between 1 and 5),
  note            text,
  created_at      timestamptz not null default now(),
  unique (meeting_id, reviewer_id)
);

alter table public.meeting_reviews enable row level security;

create policy reviews_select_party on public.meeting_reviews
  for select using (
    reviewer_id = auth.uid()
    or exists (
      select 1 from public.meeting_proposals mp
      join public.conversations c on c.id = mp.conversation_id
      where mp.id = meeting_id
        and (c.participant_a_id = auth.uid() or c.participant_b_id = auth.uid())
    )
  );

create or replace function public.submit_meeting_review(p_meeting_id uuid, p_rating int, p_note text)
returns public.meeting_reviews
language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_row public.meeting_reviews;
begin
  if v_user is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  if p_rating < 1 or p_rating > 5 then
    raise exception 'rating 1-5' using errcode = '22023';
  end if;
  insert into public.meeting_reviews (meeting_id, reviewer_id, rating, note)
  values (p_meeting_id, v_user, p_rating, nullif(trim(coalesce(p_note, '')), ''))
  on conflict (meeting_id, reviewer_id) do update
    set rating = excluded.rating,
        note = excluded.note
  returning * into v_row;
  return v_row;
end;
$$;

grant execute on function public.submit_meeting_review(uuid, int, text) to authenticated;
