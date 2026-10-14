# Phase 3 — Notes (2026-10-14)

## Shipped
- **Local verification record** (Drift v3): full business registration form
  (legal/trading name, type, ORC, TIN, VAT, address, category, contacts,
  owner Ghana Card *number — device-only, never synced*), document photos
  copied into app storage, pure-Dart validation with per-type requirements.
- **Verification screen** on both seller dashboards: status card
  (Unverified/Pending/Verified/Rejected + reviewer note), documents with
  upload state, Save / Submit / Resubmit, Sync Now.
- **SyncService**: anonymous-auth device link, remote profile upsert,
  business submission upsert (with `ca_business_id` linkage), document
  upload to the private `verification-docs` bucket + document rows, status
  pull (admin decision flows back into the app), public-key publishing when
  Verified, receipts_backup drain from the Phase 1 outbox (poison rows
  dropped, failures bump attempts and stop), registry pull.
- **Buyer registry**: verified businesses' active keys are cached locally
  keyed by the CA business ID that receipts actually carry (this linkage —
  `businesses.ca_business_id` — was the critical design fix of this phase).
  Pairing (TOFU) keys still work but are now labelled honestly: the scanner
  distinguishes "Verified seller" (registry + signature) from "signed, not
  business-verified" (pairing + signature) from unverified/tampered.
- **Admin review panel** (`admin/index.html`): static page, Supabase Auth
  email/password + `admins` table gate, pending queue, document viewing via
  signed URLs, approve / reject-with-note.
- **Schema v2** (`supabase/schema_v2_phase3.sql`): ca_business_id columns +
  index, admins + is_ca_admin(), complete RLS (public verified businesses,
  owner-scoped writes, admin review access), storage bucket + policies.
- **Key backup/recovery**: Seller Key screen exports a `CAKEYBACKUP1.` code
  (the signing seed — presented as a password-grade secret) and imports it
  on a new phone, restoring the identical key.
- **Unverified-issuer transparency**: the issued-QR screen shows a reminder
  when the seller's business is not Verified, explaining buyers won't see
  the badge. Enforcement of the badge lives buyer-side via the registry —
  a hard seller-side block was NOT imposed, because it would break
  offline/informal issuing; flipping to a hard gate is a one-flag change if
  Dennis wants it.

## Honest limits
- **Not live-tested against Dennis's Supabase project** (his URL/key are
  never shared with Muse by design). All payload builders, registry
  filtering, validation and DB behaviour are unit-tested (24 tests green);
  the network layer is thin around them. First live sync is Dennis's:
  run both SQL files → enable anonymous sign-ins → dart_defines → Sync Now.
  If Supabase returns an error, the app shows it verbatim in the sync snackbar.
- **Change-phone recovery is partial**: the signing KEY is fully restorable
  via CAKEYBACKUP1. Receipt *history* restore from receipts_backup is tied
  to the Supabase auth identity; anonymous identities are per-device, so
  history restore across phones needs the phone-OTP account linking slated
  for a later phase. Backups still protect against DB loss on the *same*
  account and give admins/auditors the record.
- Resubmission after rejection creates a fresh 'pending' state in the app;
  previously uploaded docs are not re-uploaded (upload flags persist).

- **Repo note**: `lib/core/db/app_db.g.dart` (Drift generated, ~190 KB) now
  exceeds the size the GitHub push channel can carry, so it is gitignored
  and regenerated locally with build_runner (see README "Run it"). The stale
  v2 copy was deleted from the repo in this phase — a fresh clone MUST run
  build_runner before `flutter run`.
