-- PMBA Airlines: Team Role Draft + Weekly Scorecard
-- Run this once in your Supabase project's SQL editor (Database -> SQL Editor -> New query).
-- It only creates 3 new tables -- it won't touch anything else in your project.

-- 1. Role draft state: one singleton row holding the current cycle + deviant queue.
create table if not exists role_state (
  id int primary key default 1,
  state jsonb not null,
  updated_at timestamptz not null default now(),
  constraint role_state_singleton check (id = 1)
);

-- 2. Role draft history: one row per weekly draw.
create table if not exists role_history (
  id bigserial primary key,
  round int not null,
  assignments jsonb not null,
  deviant text not null,
  created_at timestamptz not null default now()
);

-- 3. Weekly scorecard check-ins: one row per person, per week.
create table if not exists scorecard_responses (
  id bigserial primary key,
  week_key text not null,
  person text not null,
  scores jsonb not null,
  weighted_total numeric not null,
  created_at timestamptz not null default now(),
  unique (week_key, person)
);

-- Row Level Security: this is a no-login internal tool, so anyone with the
-- anon key (baked into the site's code, not secret) can read and write.
-- That's appropriate for a small trusted team; there's no user-level auth.
alter table role_state enable row level security;
alter table role_history enable row level security;
alter table scorecard_responses enable row level security;

drop policy if exists "anon read role_state" on role_state;
drop policy if exists "anon insert role_state" on role_state;
drop policy if exists "anon update role_state" on role_state;
create policy "anon read role_state" on role_state for select using (true);
create policy "anon insert role_state" on role_state for insert with check (true);
create policy "anon update role_state" on role_state for update using (true);

drop policy if exists "anon read role_history" on role_history;
drop policy if exists "anon insert role_history" on role_history;
create policy "anon read role_history" on role_history for select using (true);
create policy "anon insert role_history" on role_history for insert with check (true);

drop policy if exists "anon read scorecard_responses" on scorecard_responses;
drop policy if exists "anon insert scorecard_responses" on scorecard_responses;
create policy "anon read scorecard_responses" on scorecard_responses for select using (true);
create policy "anon insert scorecard_responses" on scorecard_responses for insert with check (true);

-- Seed: the starting draw state for the current 5-person team (Delaney, Alex, Nancy,
-- Laurent, Daniel) and 5 roles. The site needs this one row to exist so it can load.
-- No draw history is seeded -- the first "Draw roles" click creates it.
insert into role_state (id, state)
select 1, '{
  "cycle": {
    "members": ["Delaney","Alex","Nancy","Laurent","Daniel"],
    "roles": ["Team Leader","Facilitator","Scribe","Resource Investigator","Evaluator"],
    "shiftOrder": [0,1,2,3,4],
    "idx": 0
  },
  "deviantQueue": ["Nancy","Alex","Delaney","Daniel","Laurent"]
}'::jsonb
where not exists (select 1 from role_state where id = 1);
