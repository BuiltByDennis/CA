# Phase 5 — Notes (2026-10-14)

## Shipped
- **GRA-ready Tax Report & Exports** (both seller dashboards, analytics
  roles): This month / Last month / All — net sales, per-component
  VAT/NHIL/GETFund totals, grand total, computed by decoding each receipt's
  *signed payload* (the same data buyers verified), so reports cannot drift
  from issued receipts. Exports via share sheet: (1) Sales & Tax CSV shaped
  as a VAT-return working paper with a summary block, (2) flat item-lines
  CSV for accountants / QuickBooks-Xero import prep. Captured-receipt
  discounts (negative lines) correctly reduce net sales instead of
  appearing as a tax. New `Receipt.fromPayload` makes payload→model a
  first-class, tested path.
- **e-VAT readiness checklist** in the same screen (TIN on file, VAT status
  recorded, business verified, presets confirmed toggle — a stored
  self-attestation — and tax-breakdown coverage), plus
  `docs/GRA_EVAT_READINESS.md`: the clearance/VSDC model, field mapping,
  the four things only GRA/a certified integrator can grant, and the
  24-hour offline transmission-queue design reusing the existing outbox.
- **MoMo payment confirmation** (Drift v5): manual sellers can record the
  buyer's MoMo number and issue as *pending* (or already-received); History
  shows pending receipts with a **Confirm MoMo** action that records the
  transaction ID. Payment state is local workflow metadata — deliberately
  NOT in the frozen signed payload (payment can complete after the sale;
  the fiscal record is the receipt itself). Buyer phone is local-only too.
- **Share receipt**: issued screen shares the QR as a PNG + summary via the
  system share sheet (WhatsApp etc.) — the plan's "backup to WhatsApp";
  falls back to sharing the receipt code as text if image rendering fails.

## Honest limits
- **No GRA integration exists** — by design and by law: e-VAT is a
  clearance system needing CIS approval + VSDC credentials + the official
  data spec, none of which a codebase can grant itself. Phase 5 is genuine
  readiness (records, exports, mapping, queue design), not a claim.
  The app and CSVs state "not GRA-certified / not a GRA filing" in-product.
- **MTN MoMo collection APIs are not integrated**: real auto-collection
  needs an MTN MoMo merchant/API product account per business (and
  callbacks need a server). The pending→confirm flow mirrors how sellers
  actually work today (check the alert, then confirm) and records the
  transaction ID for reconciliation. Auto-confirmation is a future
  integration once a business has MoMo API credentials.
- Tax Report reads tax data from payloads; receipts issued in the payload
  **summary/overflow form** (very long receipts) carry no item lines and
  would under-report components — such receipts are counted via totals
  only. (Overflow receipts are rare; flagged here rather than hidden.)
