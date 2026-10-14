# GRA e-VAT Readiness — what CA does today, and what certification will need

**Status: CA is NOT GRA-certified and must never be described as such.**
This document records (a) how Ghana's e-VAT works at the level CA must
integrate with, (b) how CA's data already maps to it, and (c) the exact
gaps to close when GRA onboarding begins.

## How GRA e-VAT works (design basis, from Phase 0 research)
- Ghana's e-VAT is a **clearance model**: invoices from a **Certified
  Invoicing System (CIS)** are transmitted to GRA — in the POS-integrated
  variant via a **Virtual Sales Data Controller (VSDC)** — and GRA/VSDC
  returns control data (including a QR/control code) that appears on the
  customer's receipt. The tax authority sees the invoice at (or near) the
  time of sale; the seller does not self-declare after the fact.
- Systems that operate **offline must transmit within 24 hours** of
  regaining connectivity. CA's architecture already treats connectivity as
  intermittent and queues work in an outbox — see "transmission queue"
  below.
- Rates and levy structure change by law (VAT/NHIL/GETFund and reforms);
  CA keeps all rates as **configuration** (`lib/core/tax_presets.dart`),
  never hard-coded law.

## What a certified CA will need from GRA / a certified integrator
1. **CIS approval** for CA as invoicing software (or integration through an
   already-certified provider) — an administrative/legal process, not code.
2. **VSDC credentials/API access** per seller (device or API keys issued
   against the seller's TIN).
3. **The current e-VAT invoice data spec** (mandatory fields, numbering
   rules, QR/control-code format, refund/credit-note handling, transmission
   protocol + retry rules for the 24-hour offline window).
4. **TIN validation** access so seller (and B2B buyer) TINs can be checked
   at entry.

Until 1–3 exist, any "GRA integration" would be fiction — so Phase 5 built
readiness instead: correct records, correct exports, and the queue design.

## Mapping: CA receipt (Payload Spec v1) → e-VAT invoice needs
| e-VAT need | CA today | Gap |
|---|---|---|
| Seller identity + TIN | Business name in payload (`sn`, `sid`); TIN held in the verification record | TIN must join the invoice record at certification |
| Sequential fiscal numbering | `CA-YYYY-####` sequential per business (`no`) | Confirm GRA numbering rules; may need per-device/VSDC series |
| Item lines with amounts | `it[]` full lines in payload + local DB | Add per-line tax category when the spec requires it |
| Tax breakdown per component | `tx[]` lines (VAT/NHIL/GETFund…) preserved in the signed payload and used by the Tax Report | Rates must match current law at time of sale (config) |
| Totals integrity | Ed25519 signature over the payload; buyer verifies offline | GRA control code will be an ADDITIONAL authority stamp, not a replacement |
| Time of sale | `ts` (UTC seconds) in payload | — |
| Payment method | `pm` (Cash/MoMo/Bank/Card) + local MoMo confirmation tracking (Phase 5) | — |
| Refunds / credit notes | Not yet modelled | Add credit-note receipt type before certification |
| Transmission to GRA | — | Outbox design below |

## Transmission queue design (ready to build when access exists)
CA already has `sync_outbox` (Phase 1) draining to Supabase. The e-VAT
transmitter is a second consumer of the same pattern:
- On issue, enqueue `evat_transmit` with the full payload.
- A transmitter (online only) posts to the VSDC endpoint, stores the
  returned control code/QR on the receipt, and marks the row sent.
- Offline sales accumulate; on connectivity the queue drains oldest-first;
  anything approaching the 24-hour deadline raises an in-app warning.
- Failures retry with backoff and never block issuing (offline-first rule:
  a sale must complete without internet).

## What sellers can do today (Phase 5)
- **Tax Report & Exports** screen: monthly/lifetime net sales, per-component
  VAT/NHIL/GETFund totals computed from the signed payloads themselves, and
  a CSV working paper shaped for VAT-return preparation + a flat item-lines
  CSV for their accountant (QuickBooks/Xero import prep).
- **Readiness checklist** in the same screen: TIN on file, VAT status
  recorded, business verified, presets confirmed with an accountant,
  receipts carrying tax breakdowns.
- **MoMo confirmation tracking**: MoMo receipts can be issued as "pending"
  and confirmed (with transaction ID) when the money lands — so the tax
  record distinguishes invoiced from paid.

## Non-negotiables
- Never print or display "GRA certified/approved" anywhere until GRA grants
  it in writing.
- Tax presets stay labelled "confirm with your accountant" until a
  qualified review signs off the current rates.
- If GRA's spec conflicts with Payload Spec v1, the GRA spec wins for the
  fiscal copy; CA's buyer-verification design adapts around it.
