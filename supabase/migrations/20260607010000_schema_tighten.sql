-- Wave 6 part 2: schema tighten for messages.sender_id.
--
-- Companion to 20260607000000_security_hardening.sql. Split out because
-- (a) the changes here mutate table-level constraints and indexes rather
-- than function bodies, and (b) the NOT NULL switch is conditional on
-- the dataset already being clean, which is the kind of step you want a
-- standalone migration to roll back independently.
--
-- Background
-- ----------
-- 20260606010000_schema_fixes.sql swapped the messages.sender_id FK from
-- ON DELETE SET NULL to ON DELETE CASCADE (the SET NULL path was
-- unreachable because conversations cascade-delete on profile delete,
-- taking messages with them). With CASCADE in place, nothing in the
-- system creates new NULL sender_id rows, so the column should be
-- NOT NULL too — otherwise notify_message_inserted's `if new.sender_id
-- is null then return new` short-circuit is a permanent dead branch,
-- and the partial index `messages_sender_idx ... where sender_id is not
-- null` carries a predicate that filters nothing.

-- =============================================================================
-- 1. NOT NULL the sender_id column when no NULL rows remain
-- =============================================================================
do $$
declare
  v_nulls bigint;
begin
  select count(*) into v_nulls
    from public.messages
   where sender_id is null;

  if v_nulls = 0 then
    -- Already idempotent: ALTER ... SET NOT NULL is a no-op when the
    -- column already has the constraint, so re-running this migration
    -- is safe.
    alter table public.messages
      alter column sender_id set not null;
  else
    -- Leave the column nullable and surface the count for follow-up.
    -- A future migration will backfill these rows (probably as
    -- tombstones) before re-asserting NOT NULL.
    raise notice 'messages.sender_id has % NULL row(s); skipping NOT NULL', v_nulls;
  end if;
end
$$;

-- =============================================================================
-- 2. Rebuild messages_sender_idx without the now-redundant partial predicate
-- =============================================================================
-- The partial predicate `where sender_id is not null` filters zero rows
-- once the column is NOT NULL — drop and recreate as a plain b-tree.
-- Guarded so the recreate only runs when the NOT NULL flip succeeded
-- above (otherwise the partial predicate still has bite and we leave
-- the index alone).
do $$
declare
  v_is_not_null boolean;
begin
  select attnotnull
    into v_is_not_null
    from pg_attribute
   where attrelid = 'public.messages'::regclass
     and attname  = 'sender_id'
     and not attisdropped;

  if coalesce(v_is_not_null, false) then
    drop index if exists public.messages_sender_idx;
    create index if not exists messages_sender_idx
      on public.messages (sender_id);
  end if;
end
$$;
