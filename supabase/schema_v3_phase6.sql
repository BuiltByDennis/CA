-- CA — Supabase schema v3 (Phase 6, pilot): run AFTER schema_v2_phase3.sql.
-- Pilot feedback inbox. Users (incl. anonymous device links) can INSERT;
-- only admins can read.
create table if not exists feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  category text not null,
  message text not null,
  diagnostics text,
  app_mode text,
  created_at timestamptz not null default now()
);
alter table feedback enable row level security;
create policy "signed-in users send feedback" on feedback for insert
  with check (auth.role() = 'authenticated');
create policy "admins read feedback" on feedback for select
  using (is_ca_admin());
