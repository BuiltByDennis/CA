-- CA Phase 7 (Scale) — run AFTER schema.sql, schema_v2_phase3.sql and
-- schema_v3_phase6.sql. Idempotent.
--
-- Adds: referrals (seller referral program), subscriptions (paid tiers —
-- the admin activates after payment; the app only ever reads its own),
-- momo_payments (MoMo confirmation linking — rows are written ONLY by the
-- momo-callback Edge Function using the service role; sellers read their
-- own confirmed payments and apply them locally on Sync).

create table if not exists referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_code text not null,
  referred_ca_business_id text not null unique,
  created_at timestamptz not null default now()
);
create index if not exists referrals_referrer_idx on referrals (referrer_code);

create table if not exists subscriptions (
  ca_business_id text primary key,
  plan text not null default 'free' check (plan in ('free', 'pro')),
  status text not null default 'requested'
    check (status in ('requested', 'active', 'past_due', 'cancelled')),
  current_period_end timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists momo_payments (
  id uuid primary key default gen_random_uuid(),
  request_reference text not null unique,   -- CA-<receiptNo>
  ca_business_id text not null,
  receipt_no text not null,
  amount_pesewas integer,
  payer_phone text,
  status text not null default 'pending'
    check (status in ('pending', 'confirmed', 'failed')),
  provider_txn_id text,
  created_at timestamptz not null default now(),
  confirmed_at timestamptz
);
create index if not exists momo_payments_business_idx
  on momo_payments (ca_business_id, status);

alter table referrals enable row level security;
alter table subscriptions enable row level security;
alter table momo_payments enable row level security;

-- Referrals: an authenticated (incl. anonymous) user may record who
-- referred their business, and anyone signed in may count referrals by
-- code (codes are public identifiers). No updates/deletes from clients.
drop policy if exists referrals_insert on referrals;
create policy referrals_insert on referrals
  for insert to authenticated with check (true);
drop policy if exists referrals_read on referrals;
create policy referrals_read on referrals
  for select to authenticated using (true);

-- Subscriptions: clients may create/read their own request row; only
-- admins (or the dashboard, via service role) can activate.
drop policy if exists subscriptions_upsert_own on subscriptions;
create policy subscriptions_upsert_own on subscriptions
  for insert to authenticated with check (status = 'requested');
drop policy if exists subscriptions_read on subscriptions;
create policy subscriptions_read on subscriptions
  for select to authenticated using (true);
drop policy if exists subscriptions_admin on subscriptions;
create policy subscriptions_admin on subscriptions
  for all to authenticated
  using (is_ca_admin()) with check (is_ca_admin());

-- MoMo payments: sellers read their own business's payments. Writes are
-- service-role only (the callback function) — no client write policy.
drop policy if exists momo_read_own on momo_payments;
create policy momo_read_own on momo_payments
  for select to authenticated
  using (ca_business_id in (
    select ca_business_id from businesses where owner_id = auth.uid()
  ) or is_ca_admin());
