-- CA — schema v5 (Phase 8: cloud accounts + cross-device restore).
-- Run AFTER schema_v4_phase7.sql. Additive + idempotent.
--
-- Until now a phone's Supabase identity was an anonymous sign-in tied to
-- that device, so an owner's data could be backed up but never claimed
-- on another phone. Owners now attach an email + password (the anonymous
-- user is upgraded in place — same uid, nothing orphaned). These two
-- tables hold the rest of what a new phone needs to become "home":
-- the My Items price list, and one settings row (receipt design,
-- branches, staff PIN hashes, and the seller signing key ENCRYPTED with
-- a key derived from the owner's password — the server only ever stores
-- ciphertext; without the password it is useless to anyone).
--
-- Keyed by owner_id (the auth user) rather than the business row, so a
-- seller who has not submitted verification yet can still back up.

create table if not exists catalogue_backup (
  owner_id uuid not null references profiles(id) on delete cascade,
  ca_business_id text,
  item_id text not null,
  name text not null,
  unit_price_pesewas bigint not null default 0,
  barcode text,
  updated_at timestamptz not null default now(),
  primary key (owner_id, item_id)
);

create table if not exists account_backups (
  owner_id uuid primary key references profiles(id) on delete cascade,
  ca_business_id text,
  design_json text,       -- ReceiptDesign JSON (same shape as on-device)
  branches_json text,     -- [{name, location}]
  staff_json text,        -- [{name, phone, role, pinSalt, pinHash, active, createdAtUnix}] (hashes only, never raw PINs)
  key_salt text,          -- seller key wrap: PBKDF2 salt, base64
  key_nonce text,         -- AES-GCM nonce, base64
  key_ciphertext text,    -- AES-GCM ciphertext of the 32-byte Ed25519 seed, base64
  updated_at timestamptz not null default now()
);

alter table catalogue_backup enable row level security;
alter table account_backups enable row level security;

drop policy if exists "own catalogue backup" on catalogue_backup;
create policy "own catalogue backup" on catalogue_backup for all
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

drop policy if exists "own account backup" on account_backups;
create policy "own account backup" on account_backups for all
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
