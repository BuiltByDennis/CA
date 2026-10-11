# Phase 0 — Decisions Log (2026-10-11)

## Locked by Dennis
- Plan approved 2026-10-11.
- Name: **CA** — the name of the person who inspired the idea. Not an acronym. Do not invent an expansion.
- Repo: BuiltByDennis/CA (private, was empty at Phase 0 start).
- Backend: **Supabase** (backup / verification / public-key registry only — app is offline-first).

## Locked in plan
- Flutter, Android-first. State: Riverpod. Routing: go_router.
- Local DB: Drift (SQLite) — lands Phase 1 with codegen; Phase 0 uses dummy data behind the same screens.
- Signing: Ed25519 (`cryptography` pkg). QR Spec v1 frozen (docs/QR_PAYLOAD_SPEC_V1.md).
- OCR: on-device ML Kit (Phase 2). Scanner: mobile_scanner (Phase 1).
- Money: integer pesewas. Currency default GHS.
- One account, three modes; verification gates signed issuing.

## Open items (need Dennis / research)
- [ ] Final brand: logo + colours (Phase 0 palette in lib/core/theme.dart is a placeholder: deep green + gold)
- [ ] Bundle ID: scaffold uses com.careceipt.ca_receipt — confirm before Play Store
- [ ] Ghana tax presets: encode current post-2026-reform VAT/NHIL/GETFund structure as config (Phase 1 research task)
- [ ] Supabase project: create project + run supabase/schema.sql when Phase 1 auth starts (needs Dennis's Supabase account)
- [ ] Paper-test FLOWS.md with 3 real users (1 market seller, 1 POS shop, 1 buyer) before Phase 1 forms are finalised
