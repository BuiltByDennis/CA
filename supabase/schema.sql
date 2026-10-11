-- CA — Supabase schema v1 (Phase 0 draft; run in Phase 1/3 setup, NOT required for offline app use)
-- Supabase role: account backup, business verification, verified-seller public-key registry.
-- The app issues/scans receipts fully offline from its local Drift/SQLite DB; these tables are sync targets.

create extension if not exists pgcrypto;

-- One account per person/company. Phone is the primary identity (Ghana-first).
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  phone text unique,
  created_at timestamptz not null default now()
);

create table if not exists businesses (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  legal_name text not null,
  trading_name text not null,
  business_type text not null check (business_type in ('sole_prop','limited','informal','company')),
  seller_mode text check (seller_mode in ('integrated','manual')),
  orc_number text,            -- Office of the Registrar of Companies
  tin text,                   -- GRA Taxpayer Identification Number
  vat_registered boolean not null default false,
  address text, gps_lat double precision, gps_lng double precision,
  category text, contact_phone text, contact_email text,
  verification_status text not null default 'unverified'
    check (verification_status in ('unverified','pending','verified','rejected')),
  verification_note text,     -- rejection reason / admin note
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists business_members (
  business_id uuid not null references businesses(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  role text not null check (role in ('owner','manager','cashier','accountant')),
  primary key (business_id, user_id)
);

create table if not exists verification_documents (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id) on delete cascade,
  doc_type text not null check (doc_type in ('orc_certificate','tin_certificate','ghana_card','business_permit','other')),
  storage_path text not null,  -- Supabase Storage (private bucket: verification-docs)
  uploaded_at timestamptz not null default now()
);

-- The trust core: buyers cache these keys and verify receipt signatures offline.
create table if not exists seller_public_keys (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id) on delete cascade,
  public_key_b64url text not null,          -- Ed25519 public key, base64url no padding (QR Spec v1)
  status text not null default 'active' check (status in ('active','superseded','revoked')),
  created_at timestamptz not null default now()
);

-- Cloud backup of receipts (seller-issued + buyer-saved). Local DB remains the source of truth on device.
create table if not exists receipts_backup (
  id text primary key,                       -- receipt UUID from QR payload `id`
  seller_business_id uuid references businesses(id),
  payload jsonb not null,                    -- full QR Spec v1 payload
  qr_text text not null,                     -- CA1.<payload>.<signature>
  total_pesewas bigint not null,
  issued_at timestamptz not null,
  backed_up_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists receipt_templates (
  business_id uuid primary key references businesses(id) on delete cascade,
  template_style int not null default 1 check (template_style in (1,2,3)),
  logo_path text, primary_color text, footer_note text,
  payment_methods text[] not null default '{Cash}',
  tax_config jsonb not null default '{}',    -- rates are CONFIG, never hard-coded (they change)
  updated_at timestamptz not null default now()
);

-- RLS: on for every table. Owners see their businesses; public keys are public-read (that is their purpose);
-- receipts_backup readable only by the backing-up user and the seller business members.
alter table profiles enable row level security;
alter table businesses enable row level security;
alter table business_members enable row level security;
alter table verification_documents enable row level security;
alter table seller_public_keys enable row level security;
alter table receipts_backup enable row level security;
alter table receipt_templates enable row level security;

create policy "public keys are public" on seller_public_keys for select using (true);
create policy "own profile" on profiles for all using (auth.uid() = id);
create policy "owner businesses" on businesses for all using (auth.uid() = owner_id);
-- Remaining member/receipt policies are finalised in Phase 3 with the admin review panel.
