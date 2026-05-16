-- Slice 5: conversations + messages + realtime + accept_intro update

create table public.conversations (
  id                uuid primary key default gen_random_uuid(),
  participant_a_id uuid not null references public.profiles(id) on delete cascade,
  participant_b_id uuid not null references public.profiles(id) on delete cascade,
  last_message_at   timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  constraint conversations_canonical_order check (participant_a_id < participant_b_id),
  constraint conversations_no_self         check (participant_a_id <> participant_b_id)
);

create unique index conversations_pair_uq
  on public.conversations (participant_a_id, participant_b_id);
create index conversations_a_last_msg_idx
  on public.conversations (participant_a_id, last_message_at desc nulls last);
create index conversations_b_last_msg_idx
  on public.conversations (participant_b_id, last_message_at desc nulls last);

create trigger conversations_set_updated_at
  before update on public.conversations
  for each row execute function extensions.moddatetime(updated_at);

alter table public.conversations enable row level security;

create policy conversations_select_participant on public.conversations
  for select using (
    auth.uid() = participant_a_id or auth.uid() = participant_b_id
  );

create table public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id       uuid references public.profiles(id) on delete set null,
  body            text not null,
  created_at      timestamptz not null default now(),
  constraint messages_body_len check (char_length(body) between 1 and 4000)
);

create index messages_conversation_created_idx
  on public.messages (conversation_id, created_at);

alter table public.messages enable row level security;

create policy messages_select_participant on public.messages
  for select using (
    exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id
        and (c.participant_a_id = auth.uid() or c.participant_b_id = auth.uid())
    )
  );

create policy messages_insert_participant on public.messages
  for insert with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id
        and (c.participant_a_id = auth.uid() or c.participant_b_id = auth.uid())
    )
  );

create or replace function public.bump_conversation_last_message()
returns trigger language plpgsql as $$
begin
  update public.conversations
  set last_message_at = new.created_at
  where id = new.conversation_id;
  return new;
end;
$$;

create trigger messages_bump_last_message
  after insert on public.messages
  for each row execute function public.bump_conversation_last_message();

alter table public.intros
  add constraint intros_conversation_id_fkey
  foreign key (conversation_id) references public.conversations(id) on delete set null;

do $$
begin
  alter publication supabase_realtime add table public.messages;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;

create or replace function public.accept_intro(p_intro_id uuid)
returns public.intros
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller uuid := auth.uid();
  v_intro public.intros;
  v_a uuid;
  v_b uuid;
  v_conv_id uuid;
begin
  if v_caller is null then raise exception 'unauthenticated' using errcode = '28000'; end if;

  select * into v_intro from public.intros where id = p_intro_id for update;
  if not found then raise exception 'intro not found' using errcode = 'P0002'; end if;
  if v_intro.recipient_id is distinct from v_caller then
    raise exception 'only the recipient can accept' using errcode = '42501';
  end if;
  if v_intro.state <> 'delivered'::public.intro_state then
    raise exception 'intro not in delivered state' using errcode = '22023';
  end if;
  if v_intro.expires_at < now() then
    raise exception 'intro has expired' using errcode = '22023';
  end if;
  if v_intro.sender_id is null then
    raise exception 'sender no longer exists' using errcode = 'P0002';
  end if;

  if v_intro.sender_id < v_intro.recipient_id then
    v_a := v_intro.sender_id; v_b := v_intro.recipient_id;
  else
    v_a := v_intro.recipient_id; v_b := v_intro.sender_id;
  end if;

  select id into v_conv_id
    from public.conversations
   where participant_a_id = v_a and participant_b_id = v_b;

  if v_conv_id is null then
    insert into public.conversations (participant_a_id, participant_b_id)
    values (v_a, v_b)
    returning id into v_conv_id;
  end if;

  update public.intros
  set state = 'connected'::public.intro_state,
      conversation_id = v_conv_id
  where id = p_intro_id
  returning * into v_intro;

  return v_intro;
end;
$$;
