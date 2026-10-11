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
