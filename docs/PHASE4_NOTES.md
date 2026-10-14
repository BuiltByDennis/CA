# Phase 4 — Notes (2026-10-14)

## Shipped
- **Seller analytics** (`lib/core/analytics/analytics.dart`, pure + tested;
  screen shared by both seller modes): Today / 7d / 30d / All windows —
  total sales, receipt count, average basket, daily bar chart, top items by
  quantity and revenue, top buyers, payment-method split, and sales by
  cashier. Fully offline, computed from the local DB.
- **Multi-staff** (Drift v4 `staff_members`): owner adds Manager / Cashier /
  Accountant, each with their own salted-PIN. The unlock screen is now a
  person picker ("Who is using CA?"). Permission matrix is a pure, tested
  module (`lib/core/staff/staff_logic.dart`): cashiers issue+capture+history
  (no analytics, no verification); accountants get analytics+history (no
  issuing); managers everything except staff management and key export;
  key backup export is owner-only. Every issued receipt is stamped with the
  signed-in person's name (`receipts.cashier_name`, local metadata — the
  frozen QR payload v1 is unchanged, so the stamp shows in this device's
  history/analytics, not on the buyer's copy).
- **Twi language** (`lib/core/i18n/strings.dart`): English/Twi toggle on the
  home screen, persisted; home + dashboards + main actions translated.
- **Bluetooth printing** (Android): "Print QR Slip" on the issued-receipt
  screen → paired-printer picker (choice remembered) → ESC/POS slip with
  business name, items, total, the same signed QR, and cashier name.
  Real catch found by tests: thermal printers encode Latin-1 — the ₵ glyph
  and Twi letters (ɛ/ɔ) cannot print, so slip text is transliterated
  (₵→GHS, ɛ→e, ɔ→o) by `slipSafe`/`slipMoney`.

## Honest limits
- **Printing is not device-tested** (no physical printer here): byte
  generation is unit-tested; pairing/connect uses print_bluetooth_thermal's
  standard flow. First real print is Dennis's — common fixes if it fails:
  printer paired but not "connected" in its vendor app, 58mm vs 80mm width
  (slip is generated at 80mm), or the printer needing ESC/POS mode.
- **Staff enforcement is device-level** UI gating on this phone, which is
  the correct scope for a single-device business today. It is not
  server-enforced: anyone with the owner's PIN is the owner. True
  per-person accounts arrive with phone-OTP linking (later phase) — the
  `business_members` Supabase table already exists for it.
- **Twi is a first pass** covering navigation/dashboards. Deep forms are
  still English, and the Twi strings should be reviewed by a native Akan
  speaker before public release — they're all in one file for that review.
- Analytics "All" window charts the last 30 days (totals cover everything).
