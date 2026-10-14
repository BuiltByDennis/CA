# Phase 6 — Notes (2026-10-14) — pilot prep

## Shipped
- **Design Your Receipt is real now.** The Phase 0 placeholder ("full editor
  lands in Phase 3" — it didn't) is replaced by a working editor: business
  display name (used on issued receipts), footer note, 3 layout styles,
  tax-preset + payment defaults that the New Receipt form actually starts
  from. Persisted on-device (`lib/core/design/receipt_design.dart`).
- **Getting Started onboarding cards** on all three dashboards: live
  checklist computed from the local DB (paired a seller key / first scan;
  designed receipt / verification submitted / first issue / key backed up;
  first capture), deep-linking each step, auto-hiding when complete,
  dismissible. Key-backup completion is tracked from the Seller Key export.
- **Receipt detail screen**: tapping any History row shows the full receipt
  from its signed payload — items, tax lines, total, verified chip, payment
  method/status, MoMo transaction ID, cashier — with Share, and Print for
  issued receipts.
- **Help & Feedback**: offline quick-start guides per mode; feedback form
  (Bug/Confusing/Idea/Other) with an optional, content-free diagnostics
  summary (mode, counts, verification status) the user can see described
  before sending. Sends to the Supabase `feedback` table
  (`schema_v3_phase6.sql`; insert-only for signed-in/anonymous users, admins
  read) when a backend is configured; otherwise the screen offers the share
  sheet so pilot feedback is never silently lost.
- **Pilot kit** (`docs/PILOT_KIT.md`): recruiting profile (seller+buyer
  pairs), a setup-day script that includes the two-phone airplane-mode exit
  test, week-1 observation list, the 5 pilot questions, an issue-log table,
  pass criteria for Phase 7, and the honest limitations to state upfront.
- App version set to the pilot build: `0.6.0+6`, shown on Home.

## Honest limits
- Onboarding facts come from THIS device's DB (a restored phone starts
  fresh) — correct behaviour for first-run guidance.
- Feedback delivery depends on Dennis's Supabase setup like everything
  server-side; the share fallback covers the un-configured case.
- Nothing in this phase was device-tested; the pilot itself is the test.
  Phase 7 (scale) should be gated on the pilot kit's success criteria,
  not on enthusiasm.
