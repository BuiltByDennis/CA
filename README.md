# CA — Scan-to-Receive Electronic Receipts

**CA** is a Flutter app that turns any receipt into a signed QR code the buyer scans and keeps forever — no paper, no re-typing, fully offline.

Named after CA, the person who inspired the idea.

## Who it's for (one account, three modes)
- **Buyers** — individuals & companies: scan for a receipt, keep a searchable history for warranty, returns and expenses.
- **Sellers with a receipt system already** — capture a photo of your existing POS receipt, approve the extracted details, and CA issues the QR.
- **Sellers with manual (handwritten) receipts** — farmers, market women, hawkers: design your receipt once, then issue a new one in under 30 seconds from your phone.

Sellers register their business and get **verified** before they can issue signed receipts. Only verified sellers' receipts carry the Verified badge — signatures are checked on the buyer's phone, offline, using Ed25519 (see `docs/QR_PAYLOAD_SPEC_V1.md`).

## Principles
1. **Offline-first.** If a feature needs internet to complete a sale or a scan, it's a bug. Local DB (Drift/SQLite) is the source of truth on device.
2. **Supabase is support, not the engine** — account backup, business verification, and the verified-seller public-key registry only.
3. **Money is integer pesewas.** Never floats.
4. **OCR never auto-issues.** A human approves every captured receipt.
5. **Tax rates are config, never hard-coded.**

## Status
- [x] Phased build plan approved (`docs/BUILD_PLAN.md`)
- [x] App scaffold: role picker → 3 navigable dashboards, shared grouped History
- [x] QR Payload Spec v1 + working Ed25519 signer/verifier (`lib/core/receipt_signer.dart`)
- [x] Manual seller demo: New Receipt screen issues a real signed QR from a sample receipt
- [x] Supabase schema v1 draft (`supabase/schema.sql`)
- [x] Phase 1 (2026-10-11): local account + PIN auth (offline), Drift DB, real New Receipt form (items/tax presets/payment -> persistent seller key -> signed QR -> saved), real buyer scanner (mobile_scanner) with seller-key pairing QR + offline verify/save, DB-backed grouped History, Supabase config layer (docs/CONNECT_SUPABASE.md)
- [x] Phase 2 (2026-10-14): integrated-seller Capture — on-device ML Kit OCR, pure-Dart receipt parser (11 parser tests: totals + receipt numbers correct on 9/9 clean samples, garbled sample flagged), Review & Approve screen with check-this highlighting and printed-vs-CA total comparison, Drift v2 (original receipt no.), signed QR on approval (docs/PHASE2_NOTES.md)
- [ ] Phase 1 exit test (needs Dennis + 2 phones): create Supabase config per docs/CONNECT_SUPABASE.md, install on seller + buyer phones, seller issues, buyer scans Seller Key then receipt — in airplane mode, under a minute

## Run it
```bash
flutter pub get
flutter run
```

## Docs
- `docs/BUILD_PLAN.md` — the full phased plan
- `docs/QR_PAYLOAD_SPEC_V1.md` — the QR protocol (versioned, frozen for v1)
- `docs/FLOWS.md` — buyer / integrated seller / manual seller / verification flows
- `docs/PHASE0_DECISIONS.md` — locked decisions & open items
