# CA Phase 7 — Scale (implementation notes)

Phase 7 was started on Dennis's instruction (2026-10-15) after the
Supabase setup was completed, ahead of the pilot-gate criteria in
docs/PILOT_KIT.md. The gate remains the right way to judge *demand*;
nothing here removes the need to run the pilot.

## Shipped in the app (v0.7.0)

1. **Multi-branch businesses** — Branches screen (both seller dashboards):
   add branches, choose which branch this phone sells from. The active
   branch name is stamped onto issued receipts (locally, like the cashier
   stamp — QR payload v1 unchanged) and Analytics gains a branch filter.
2. **Inventory-lite** — Stock screen: every item ever sold, total sold,
   and — once the seller enters a physical count — an estimated on-hand
   (count minus sales since the count), flagged low at ≤ 5. No count is
   ever invented: uncounted items show sales only.
3. **Referral program** — Refer screen: a stable code per business
   (CA-XXXXXX, derived from the business ID), share sheet, and a live
   count of sellers who joined with the code. New sellers enter a code on
   the Business Verification form; Sync records it (schema_v4).
4. **Paid tiers** — Free keeps everything the pilot shipped: issuing and
   scanning are NEVER gated (a sale must work offline, unconditionally).
   Pro = unlimited branches + unlimited staff (Free: main shop + 1 branch, 3 staff).
   Plans screen requests Pro → row in `subscriptions` (status requested);
   the admin activates after payment; the tier reaches phones on Sync.
5. **MoMo confirmation linked to receipts** — every pending MoMo receipt
   now carries the payment reference CA-<receiptNo>. Sync pulls confirmed
   payments from `momo_payments` and marks those receipts paid with the
   provider transaction ID automatically. The callback receiver
   (supabase/functions/momo-callback) is written and deployable.
6. **iOS readiness** — Info.plist usage descriptions for camera, photo
   library and Bluetooth are in. An iOS CI workflow is provided as a
   hand-off file (Dennis creates it via GitHub web, like build-apk.yml).

## Activation steps that are NOT code (Dennis / CA business)

- Run `supabase/schema_v4_phase7.sql` in the SQL Editor.
- **MoMo auto-confirmation** goes live only with an MTN MoMo merchant API
  account: deploy the edge function, set CA_CALLBACK_SECRET, and have the
  payment-initiation step create `momo_payments` rows (with
  ca_business_id) when requesting payment. Until then, manual Confirm in
  History remains the flow — unchanged.
- **Pro billing**: activation is manual after payment confirmation.
  Wiring a payment provider checkout (e.g. Paystack) needs the business's
  provider keys; the subscriptions table already models the states.
- **iOS distribution** needs an Apple Developer account ($99/yr) and
  signing in Xcode/App Store Connect. The CI build only proves the app
  compiles for iOS unsigned.
