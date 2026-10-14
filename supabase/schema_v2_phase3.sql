-- CA — Supabase schema v2 (Phase 3): run AFTER schema.sql, in the SQL Editor.
-- Adds: ca_business_id linkage, admins, complete RLS policies, storage bucket.

-- 1) Link Supabase rows to the CA business ID used inside receipt QR payloads
--    (payload `sid`, e.g. 'biz-0244123456'). Without this, the buyer registry
--    cannot map a published key to the ID a receipt actually carries.
alter table businesses add column if not exists ca_business_id text;
create index if not exists businesses_ca_id_idx on businesses (ca_business_id);
alter table seller_public_keys add column if not exists ca_business_id text;

-- 2) Admins (verification reviewers). Add a user: create them in
--    Authentication → Users, then insert their id here (see admin/README.md).
create table if not exists admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table admins enable row level security;
create policy "admins can read admins" on admins for select
  using (auth.uid() = user_id);

create or replace function is_ca_admin() returns boolean
language sql security definer set search_path = public as
$$ select exists (select 1 from admins where user_id = auth.uid()) $$;

-- 3) Complete RLS policies (schema.sql left these for Phase 3).
-- Businesses: owners manage theirs; VERIFIED businesses are public (registry);
-- admins see and update all (for review).
create policy "verified businesses are public" on businesses for select
  using (verification_status = 'verified');
create policy "admins manage businesses" on businesses for all
  using (is_ca_admin()) with check (is_ca_admin());

-- Verification documents: owner (via their business) + admins.
create policy "owner reads own verification docs" on verification_documents for select
  using (exists (select 1 from businesses b where b.id = business_id and b.owner_id = auth.uid()));
create policy "owner adds own verification docs" on verification_documents for insert
  with check (exists (select 1 from businesses b where b.id = business_id and b.owner_id = auth.uid()));
create policy "admins read verification docs" on verification_documents for select
  using (is_ca_admin());

-- Public keys: owners publish for their business; admins manage.
create policy "owners publish keys" on seller_public_keys for insert
  with check (exists (select 1 from businesses b where b.id = business_id and b.owner_id = auth.uid()));
create policy "admins manage keys" on seller_public_keys for all
  using (is_ca_admin()) with check (is_ca_admin());

-- Receipt backups: users back up and read only their own.
create policy "own receipt backups" on receipts_backup for all
  using (auth.uid() = backed_up_by) with check (auth.uid() = backed_up_by);

-- Members/templates: owner of the business.
create policy "owner business members" on business_members for all
  using (exists (select 1 from businesses b where b.id = business_id and b.owner_id = auth.uid()));
create policy "owner receipt templates" on receipt_templates for all
  using (exists (select 1 from businesses b where b.id = business_id and b.owner_id = auth.uid()));

-- 4) Storage: private bucket for verification documents.
insert into storage.buckets (id, name, public)
values ('verification-docs', 'verification-docs', false)
on conflict (id) do nothing;

create policy "users upload verification docs" on storage.objects for insert
  with check (bucket_id = 'verification-docs' and auth.role() = 'authenticated');
create policy "users read own verification docs" on storage.objects for select
  using (bucket_id = 'verification-docs' and (owner = auth.uid() or is_ca_admin()));
create policy "admins read all verification docs" on storage.objects for select
  using (bucket_id = 'verification-docs' and is_ca_admin());
