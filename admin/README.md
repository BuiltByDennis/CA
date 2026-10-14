# CA Admin — Verification Review Panel

A single static page (`index.html`). No build, no server code: it talks to
your Supabase project directly, protected by Row Level Security.

## Setup (once)
1. **Run the SQL**: Supabase dashboard → SQL Editor → run `supabase/schema.sql`
   (if not already), then `supabase/schema_v2_phase3.sql`.
2. **Enable email auth** (it is on by default) and **Anonymous sign-ins**
   (Authentication → Sign In / Providers → Anonymous) — the app uses
   anonymous sign-in to link devices for sync.
3. **Create your admin user**: Authentication → Users → Add user (email +
   password). Copy the user's UUID.
4. **Make them an admin**: SQL Editor →
   `insert into admins (user_id) values ('THE-UUID');`
5. **Serve the page**: open `index.html` from any static host or locally
   (e.g. `python3 -m http.server` in this folder). It must be served over
   http(s), not `file://`, for the Supabase JS module to load.

## Daily use
1. Enter the Project URL + public key once (stored in this browser only).
2. Sign in with the admin email/password.
3. Review **Pending** businesses: check details + document photos.
4. **Approve** (seller gets the Verified badge; their public key is published
   to the buyer registry on their next sync) or **Reject with a note** (the
   seller sees the note in the app and can fix + resubmit).

Security notes: the panel only ever uses the public key — RLS does the real
protection. Never paste a `service_role` key into this page (it is not needed
and would bypass all security if this browser were compromised).
