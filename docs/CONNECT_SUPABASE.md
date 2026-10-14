# Connect CA to your Supabase project

The app works 100% offline without Supabase. Connecting Supabase adds:
account backup, business verification, and the verified-seller public-key
registry (used from Phase 3). Connection takes ~5 minutes:

## 1. Create the tables
In your Supabase dashboard: **SQL Editor → New query** → paste all of
`supabase/schema.sql` → **Run**. You should see the 7 tables under
**Table Editor**: profiles, businesses, business_members,
verification_documents, seller_public_keys, receipts_backup, receipt_templates.

## 2. Copy your public config
**Settings → API** — copy:
- **Project URL** (looks like `https://abcdxyz.supabase.co`)
- **Publishable / anon key** (`sb_publishable_...` or the long `eyJ...` anon key)

> ⚠️ The **service_role** key on that page is a master key. Never put it in
> the app, never commit it, never paste it in chat. The app only ever uses
> the public key + Row Level Security from the schema.

## 3. Give the app the config (kept out of git)
```bash
cp dart_defines.example.json dart_defines.json
# edit dart_defines.json with your URL + public key
flutter run --dart-define-from-file=dart_defines.json
```
`dart_defines.json` is gitignored. For Play Store builds, pass the same file
to `flutter build appbundle --dart-define-from-file=dart_defines.json`.

## 4. Check it worked
Open the app → the home screen shows a status card:
**"Supabase: configured"** means the app found the config and initialised.
Actual data sync (receipt backup, key registry publishing) switches on in
Phase 3 — Phase 1 only wires and verifies the connection.

## What if I do nothing?
Nothing breaks. Every Phase 1 feature — accounts, PIN, issuing, scanning,
verification, history — runs from the phone's local database.

## Phase 3 additions (verification + sync)
1. **Run the v2 SQL**: SQL Editor → paste `supabase/schema_v2_phase3.sql` → Run.
   It adds the `ca_business_id` linkage, the `admins` table, complete RLS
   policies, the verified-businesses public read (buyer registry), and the
   private `verification-docs` storage bucket.
2. **Enable Anonymous sign-ins**: Authentication → Sign In / Providers →
   Anonymous → Enable. The app links each device to Supabase anonymously for
   backup/verification sync; the local PIN remains the app's lock.
3. **Set up the admin panel**: see `admin/README.md` (create an auth user,
   insert them into `admins`, open `admin/index.html`).
4. In the app: Home → **Sync Now** (or Business Verification → Sync Now)
   pushes receipt backups + verification submissions, pulls verification
   status, and caches verified sellers. The seller's public key is published
   to the registry automatically once their business is Verified and they sync.
