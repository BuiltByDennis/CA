# CA — Scan-to-Receive Electronic Receipt System
**Repo:** https://github.com/BuiltByDennis/CA.git (returns 404 publicly on 2026-10-11 — private or not yet created; confirm visibility/access before first push)
**Stack decision:** Flutter (single codebase, Android-first, iOS second) · Offline-first · Ghana-first, global-ready

---

## 1. The core idea — in one sentence
The seller creates a receipt once, the app turns it into a **signed QR code**, the buyer scans it and owns a permanent, verifiable copy — **with no internet, no paper, and no re-typing by anyone.**

Critical design rule: **The QR must be trustworthy offline.**
A plain QR containing text can be faked by anyone. CA receipts are:
1. Serialised (seller ID, receipt no., items, totals, tax, date/time)
2. Compressed (fits a scannable QR — target < 1,500 bytes; if more, QR holds ID + hash + key totals and full detail syncs/derives from ID)
3. **Digitally signed** with the seller-device private key (Ed25519), issued only after business verification
4. Verified on the buyer's phone against the seller's public key — cached offline after first encounter / bundled registry sync

Buyer sees: ✅ Verified seller, receipt #X, total GH₵ Y — or ⚠️ Unverified / tampered.

That signature is the moat. Without it, CA is just a QR generator.

---

## 2. One account, three modes (not three apps)

One User account → user picks a role at signup, can add/switch later:

| Mode | Who | Dashboard |
|---|---|---|
| **Buyer** | Individuals, companies, procurement/expense staff | [Scan for Receipt] big button · Receipt History (search, filter by seller/date/category, export) |
| **Seller — Integrated** | Shops, supermarkets, pharmacies, companies with POS/ERP/printer already | [Capture Receipt] · Receipt History grouped by buyer/company + date/time · Approvals queue |
| **Seller — Manual** | Farmers, market women, hawkers, traders, small shops with receipt books | [New Receipt] · Receipt History (same grouping) · Receipt Design (set at signup, editable) |

A company can be *both* buyer and seller under one account — role is per-business/profile, not per-login. That matters for B2B.

### Account / Business model
- `User` (phone + PIN / biometric first — email optional; phone is identity in Ghana, OTP when online, offline PIN unlock)
- `Business` (0..many per user): legal name, trading name, type (sole prop / ltd / informal), ORC registration no., TIN, VAT status (registered / not), address + GPS, category, logo, contact, Ghana Card of owner (for sole props)
- `Membership`: user ↔ business, role: Owner / Cashier / Manager / Accountant (multi-staff from Phase 4)
- **Verification states:** `Unverified → Pending → Verified / Rejected (with reason)`. 
  - Unverified: can design receipts, create drafts, use app in demo
  - Verified only: can issue *signed* receipts, QR carries the Verified badge
  - This protects buyers and is the selling point to GRA / corporates

---

## 3. The three flows — transparent, step by step

### A. Buyer flow
```
Open app (offline OK) → Tap Scan → Point at seller's QR (on screen, printed slip, or phone)
→ App verifies signature + seller verification status instantly, offline
→ Receipt animates in: seller, items, tax breakdown, total, payment method
→ [Save] (auto-save default) → lands in History
→ Later: search "Makro / cement / March", filter, tap → detail, share PDF, 
  add note/category (e.g. "Office", "Farm inputs"), use for warranty / returns / expense claim
```
Edge cases designed in: duplicate scan (detect receipt ID, show "already saved"), tampered QR (hard warning, do not save as verified), seller not yet known (save with "signature pending verification — will confirm when online").

### B. Seller — Integrated (has a system already)
```
Seller's POS/ERP prints/displays a receipt on PC as today
→ In CA: Tap Capture → Scan/photo that receipt (screen capture, photo, or upload image/PDF)
→ On-device OCR (ML Kit, offline) extracts: seller header, items, qty, prices, taxes, total, receipt no., date
→ App shows side-by-side: photo vs extracted fields, LOW-CONFIDENCE fields highlighted
→ Seller corrects if needed → [Approve] ← human-in-the-loop is non-negotiable; OCR is never auto-issued
→ CA generates signed QR + a clean CA digital receipt (their original no. kept as reference)
→ Show QR on phone / print as small slip / share via WhatsApp → Buyer scans
→ Saved to History, grouped by buyer/company name, then date/time
```
Phase 5 upgrade path (do NOT build first): direct integrations — print-driver / virtual printer, CSV import, API / webhook from POS, desktop companion — so capture-by-photo becomes the fallback, not the main route.

### C. Seller — Manual (handwritten receipt book today)
```
At signup: Design Receipt wizard (5 min, icon-led)
  1. Business name, contact, location  2. Logo/photo of shop sign (or pick icon + colours)
  3. Template style (3 clean layouts)  4. Tax setup: "Do you charge VAT?" → simple toggle + rates preset for Ghana
  5. Payment methods accepted (Cash / MoMo / Bank / Card)  6. Footer note ("Thank you", returns policy, Twi/English)
  → Live preview on a sample receipt

Daily use: Tap New → 
  Buyer name (optional, or pick from recent buyers) → Add items: name, qty, unit price
  (recent/favourite items are one tap — a tomato seller shouldn't retype "Tomatoes" daily)
  → App calculates subtotal, discount, levies/VAT if enabled, TOTAL — large, clear
  → Payment method → [Issue Receipt] → Big QR on screen, buyer scans on the spot
  → No buyer phone / no scan? Share via WhatsApp/SMS link, or print if a Bluetooth printer exists
  → Auto-saved to History, same grouping as Integrated
```
Design for low literacy / speed: big tap targets, icons + photos for items, voice input for item names (later phase), Twi/Ga/Ewe labels toggle, works in bright sunlight (high contrast), completes a receipt in <30 seconds.

---

## 4. How receipts work today — and where they break

**Large businesses:** POS / ERP (e.g. QuickBooks, Tally, Sage, Lightspeed, Square, custom) records sale → calculates tax → sends to a thermal printer (heat on coated paper, no ink) → duplicate stored in their system for accounting/audit. Increasingly in Ghana this must also clear GRA e-VAT: the invoice is transmitted to GRA's Virtual Sales Data Controller, validated/signed, and a GRA QR + control ID comes back to put on the invoice before issuing. Offline systems may stamp locally but must transmit within 24h of connectivity returning. [Sources: Fonoa/GRA e-VAT explainer; VATUpdate Ghana briefing]

**Small businesses:** Cheaper POS, Excel, or an ECR cash register. Receipt is printed, accounts are reconciled manually at night, paper copies filed in boxes.

**Informal sellers:** Handwritten receipt book (duplicate copy stays in book), or *no receipt at all* — just verbal / MoMo confirmation SMS.

**Where it all breaks — CA's opportunity:**
1. Thermal paper **fades in weeks/months** and is lost — buyers can't prove warranty, expenses, or returns
2. Paper = recurring cost (rolls, printers, maintenance) and waste
3. Handwritten = errors, no totals/tax discipline, no records when the book is lost/damaged
4. Fraud: anyone can print/hand-write a fake receipt; no verification exists for paper
5. No data: sellers can't answer "what did I sell last month, to whom?" without counting books
6. Buyers (especially companies) must **re-type paper receipts** into accounting — slow, error-prone
7. Tax/audit pain: records must be kept for years; paper archives fail audits

## 5. Why businesses would pay for / adopt CA

Do not sell "digital receipts." Sell these outcomes:

1. **Save money:** no thermal rolls / receipt books for CA receipts; issued from a phone they already own
2. **Trust that sells:** Verified badge + tamper-proof QR — corporates and institutions will prefer (eventually require) sellers who can issue verifiable receipts for procurement
3. **GRA-ready:** structure every receipt GRA e-VAT-style from day 1 (unique no., seller TIN, tax breakdown, QR, timestamp, 6-year archive) and pursue Certified Invoicing System alignment in Phase 5 — *do not claim GRA certification until GRA grants it*
4. **Free bookkeeping:** History = a sales ledger automatically. Daily/weekly/monthly totals, top items, top customers — no counting books
5. **Repeat customers:** buyer history = a customer list; a market woman can see who buys regularly
6. **Dispute-proof:** signed receipt settles "I paid you / I didn't buy this" arguments for both sides
7. **Buyer pull:** buyers demand CA receipts for warranty, expense claims, and records — sellers adopt because customers ask (network effect: every receipt issued recruits a buyer, every buyer asks the next seller)
8. **Works where they work:** fully offline, cheap Android phones, no POS purchase — the informal sector is *included*, not told to buy hardware

**Business model (propose, validate in pilot):**
Free for buyers, always. Free for manual sellers up to e.g. 30 receipts/month. Paid seller tiers (monthly, MoMo) for unlimited receipts, multi-staff, analytics, integrations, bulk export for accountants. Per-receipt pricing will kill informal adoption — avoid it.

---

## 6. Architecture — offline-first, honestly

```
Flutter app
├── UI: go_router, Riverpod (or Bloc — pick ONE at Phase 0, Riverpod recommended for speed)
├── Local DB: Drift (SQLite) — the SOURCE OF TRUTH on device. All features work from it.
├── Secure store: flutter_secure_storage — device signing key, PIN hash
├── OCR: google_mlkit_text_recognition — on-device, offline
├── QR: mobile_scanner (scan) + qr_flutter (generate)
├── Crypto: Ed25519 signing/verification (e.g. cryptography package)
├── PDF/Share: pdf + share_plus — receipt PDF export, WhatsApp share
└── Sync (when online): queued outbox pattern — receipts, verification docs, public-key registry
    Backend (Phase 3+): Supabase (Postgres + Auth + Storage) recommended — Dennis already runs it in production
    on CampusStay; fastest path, low cost. Alternative: Firebase. Decide in Phase 0, don't build custom backend first.
    Backend does: accounts backup, business verification review (admin web panel), public-key/seller registry,
    receipt backup & cross-device restore, analytics (consented, aggregated). Backend is NEVER required to issue/scan.
```

**Sync rule printed on the wall:** *If a feature needs internet to complete a sale or a scan, it's a bug.*

**Receipt data model (core):**
`Receipt { id (UUID), receiptNo (seller-sequential), sellerBusinessId, sellerDeviceKeyId, buyerName?, buyerBusinessId?, items[{name, qty, unit, unitPrice, amount}], subtotal, discount, taxLines[{name, rate, amount}], total, currency (GHS default), paymentMethod, issuedAt, source (manual|captured|integrated), originalReceiptNo?, status (issued|void|refunded), signature, templateId }`
Money in **pesewas (integers)** everywhere — never floats. (Lesson carried from CampusStay.)

---

## 7. Phased build plan

### Phase 0 — Decide & Design (Week 1) — NO production features yet
- Confirm repo access, name/app identity (working name "CA" — confirm what CA stands for & final brand), bundle ID
- Lock: state management, backend choice, signing approach, QR payload spec v1 (write it as a doc — it's a protocol, version it)
- Figma/wireframes for the 3 dashboards + 3 flows above; test flow drawings with 3 real users (1 market seller, 1 shop with POS, 1 buyer) — paper test before code
- Ghana tax preset research: current VAT/levies structure post-2026 reform (NHIL/GETFund now input-deductible, COVID levy abolished) — encode as *config*, not hard-coded, rates will change again
- **Exit criteria:** signed-off flow diagrams, QR spec v1, data model v1, screen list

### Phase 1 — MVP Core: Manual Seller + Buyer (Weeks 2–4) ★ the shippable heart
- App shell, one-account auth (phone + PIN, offline unlock), role picker
- Business registration form (unverified state) + Design Receipt wizard
- Manual: New Receipt (items, totals, tax toggle), Issue → signed QR, History (grouped by buyer/company → date/time, search)
- Buyer: Scan → verify signature → Save, History (search/filter/detail/share PDF)
- Local DB, offline 100%, void receipt (with reason, never delete — audit trail)
- **Exit criteria:** A market seller and a buyer complete a real transaction on two phones, in airplane mode, in <1 minute. If this fails, nothing else matters.

### Phase 2 — Integrated Seller: Capture (Weeks 5–6)
- Capture flow: camera/gallery/PDF → on-device OCR → extraction parser (items/totals/date/receipt no.) → side-by-side review with confidence highlights → Approve → signed QR → History (same grouping)
- Parser test set: collect 30+ real Ghana receipt photos (supermarket, pharmacy, fuel, hardware) and measure extraction accuracy before shipping
- **Exit criteria:** ≥90% of totals/receipt numbers extracted correctly on test set; correction takes <20 seconds when wrong

### Phase 3 — Verification & Trust (Weeks 7–8)
- Business verification submission (ORC/TIN/Ghana Card uploads), Admin review panel (simple web — Supabase + small admin UI), Verified/Rejected with reasons, re-submit
- Public-key registry sync: buyer phones download/cache verified seller keys; Verified badge logic in scan result + history
- Receipt backup/restore (account sync when online), change-phone recovery
- **Exit criteria:** unverified seller cannot issue a "Verified" receipt; tampered QR is caught in testing 100%

### Phase 4 — Make it a business tool (Weeks 9–11)
- Seller analytics: day/week/month sales, top items, top buyers — all computed locally, works offline
- Buyer power features: categories/notes, expense export (CSV/PDF by period — for employers/accountants), warranty watch (flag receipts with warranty items)
- Multi-staff: cashier accounts under one business, each receipt stamped with cashier; owner sees all
- Favourite items / price list for manual sellers; repeat-buyer quick-pick; Bluetooth thermal printer support (print the QR slip for buyers without smartphones)
- Language: Twi first (then Ga/Ewe) UI toggle; large-text mode

### Phase 5 — Integrations & Compliance (Weeks 12+)
- GRA path: apply/align as Certified Invoicing System; when online, transmit to GRA VSDC and embed GRA QR/control data alongside (or as) CA QR where required; offline queue with 24h transmission rule
- Integrated-seller upgrades: virtual printer / desktop companion, CSV/POS imports, public API for ERPs
- Company buyer features: team expense inbox (staff scan, finance approves), accounting exports (QuickBooks/Tally format)
- Share fallbacks: receipt via WhatsApp deep link, SMS code for feature phones (buyer later claims it in app)

### Phase 6 — Pilot & Harden (parallel from Phase 3, formal after Phase 4)
- Pilot cohort: 10 sellers (5 manual, 3 integrated, 2 large-ish) + their real buyers, 4 weeks, in-person onboarding
- Measure: receipts issued/week/seller, scan rate (did buyers actually scan?), OCR correction time, time-to-issue vs paper, failures in the wild (low-end phones, sunlight, damaged screens)
- Fix top 10 pilot issues, Play Store release (closed → open), crash/analytics (consented), support via WhatsApp

### Phase 7 — Scale (only after pilot retention is real)
- Multi-branch businesses, inventory-lite (stock counts from items sold), MoMo payment confirmation linked to receipt, iOS, referral program for sellers, paid tiers switched on

---

## 8. Risks & honest open questions (decide in Phase 0)
1. **Name/brand:** What is "CA"? Final name, logo, colours — needed before Play Store / design wizard templates
2. **Repo access:** github.com/BuiltByDennis/CA returns 404 publicly (11 Oct 2026) — private repo needs collaborator/auth setup, or it doesn't exist yet
3. **Two-sided cold start:** buyers only benefit if sellers issue; sellers only bother if buyers scan. Pilot must recruit seller+their-buyers *pairs*, not either side alone
4. **QR size:** receipts with 30+ items won't fit one QR with a signature. Spec must handle: QR = summary+signature+ID, full detail via seller-phone→buyer-phone share or sync. Decide in QR spec v1
5. **Key loss:** seller loses phone = loses signing key = past receipts unverifiable from new device. Mitigation: encrypted key backup at verification (Phase 3), key rotation with registry history
6. **GRA claims:** Never market "GRA approved/certified" until it is true. Market "GRA-ready records" in the meantime
7. **OCR reality:** photographing a *PC screen* (moiré, glare) is harder than photographing paper. Test this specifically in Phase 2 — screen-capture import may need to be the primary path, photo the fallback

---

## 9. Recommended immediate next step
**Approve this plan, then do Phase 0 only:** I scaffold the Flutter repo (offline shell, Drift DB, role navigation for all 3 dashboards with dummy data), write QR Payload Spec v1, and draft the 3 flow diagrams as screens — you review working navigation before we build the Phase 1 transaction heart.
