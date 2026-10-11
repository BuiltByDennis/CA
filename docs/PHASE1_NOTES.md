# Phase 1 — Notes (2026-10-11)

## Shipped
- Local account (name, phone, mode, business name) + PIN (salted SHA-256 in secure storage), offline unlock, lock button.
- Drift DB (schema v1): profiles, receipts, receipt_items, seller_keys, sync_outbox. Receipts queue a `receipt_backup` outbox row — Phase 3 sync drains it to Supabase.
- Seller signing key: persistent Ed25519 seed in secure storage (was: new demo key every issue in Phase 0).
- New Receipt form: dynamic items, qty, GH₵ price -> pesewas, favourite-item chips, tax preset toggle (VAT/NHIL/GETFund — VERIFY rates), payment method, sequential receipt numbers, signed QR screen.
- Buyer scanner: mobile_scanner; CAKEY1 pairing QR (trust-on-first-use) then CA1 receipts verify offline; unverified/tampered/duplicate states handled; saved to History.
- History is DB-backed and grouped (issued: by buyer; saved: by seller) with Verified chips.
- Supabase: config layer via dart-defines (docs/CONNECT_SUPABASE.md). Home shows configured/not. No data sync yet by design.

## Known Phase 1 limits (honest)
- No device test yet — camera scanner + two-phone airplane-mode exit test needs real phones (Dennis).
- Tax presets are simple % on subtotal; real GRA VAT treatment is Phase 5 work.
- Pairing QR is TOFU trust; Phase 3 Supabase registry replaces it for verified sellers.
- Supabase Auth not used yet; local PIN is the Phase 1 auth (by design, offline-first). Backup/verification in Phase 3 will link the Supabase account.
- Integrated Seller Capture/OCR is Phase 2 (screen is still an explainer).
