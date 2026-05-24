-- Phase P1 / Chunk 01
-- Practice question bank table for web + future Android sync.

begin;

create table if not exists public.practice_question_bank (
  question_id text primary key,
  subject text not null,
  unit text not null default '',
  topic text not null,
  question_text text not null,
  option_a text not null default '',
  option_b text not null default '',
  option_c text not null default '',
  option_d text not null default '',
  answer_key text not null check (answer_key in ('A','B','C','D')),
  difficulty text not null default '',
  solution text not null default '',
  active boolean not null default true,
  pools text[] not null default array['practice']::text[],
  solution_mode text not null default 'full',
  question_order integer not null default 0,
  shuffle_bucket integer not null default 0 check (shuffle_bucket between 0 and 999999),
  source_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (length(trim(question_id)) > 0),
  check (length(trim(subject)) > 0),
  check (length(trim(topic)) > 0),
  check (length(trim(question_text)) > 0)
);

create or replace function public.app_practice_set_shuffle_bucket()
returns trigger language plpgsql as $$
begin
  new.shuffle_bucket := ((('x' || substr(md5(coalesce(new.question_id, '')), 1, 8))::bit(32)::bigint) % 1000000)::integer;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_practice_question_bucket on public.practice_question_bank;
create trigger trg_practice_question_bucket
before insert or update on public.practice_question_bank
for each row execute function public.app_practice_set_shuffle_bucket();

create index if not exists idx_practice_bank_topic
  on public.practice_question_bank(active, subject, topic, question_order, question_id);
create index if not exists idx_practice_bank_shuffle
  on public.practice_question_bank(active, subject, topic, shuffle_bucket, question_id);

alter table public.practice_question_bank enable row level security;

drop policy if exists p_p1_practice_read on public.practice_question_bank;
create policy p_p1_practice_read on public.practice_question_bank
for select to authenticated
using (public.app_event_is_admin() or (active = true and 'practice' = any(pools)));

drop policy if exists p_p1_practice_admin_all on public.practice_question_bank;
create policy p_p1_practice_admin_all on public.practice_question_bank
for all to authenticated using (public.app_event_is_admin())
with check (public.app_event_is_admin());

grant select, insert, update, delete on public.practice_question_bank to authenticated;

commit;
