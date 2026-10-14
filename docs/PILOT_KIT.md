# CA Pilot Kit — running the first real-world pilot (Phase 6)

Goal: prove CA with real money, real phones, real receipts — and learn what
breaks before scaling. The pilot pairs sellers with THEIR OWN buyers,
because a receipt only matters when both sides hold the app.

## Who to recruit (5 pairs is plenty)
- 2 **manual sellers** (market stall, provisions shop, farmer) + 2–3 of their
  regular buyers each.
- 2 **integrated sellers** (shop with a POS/printed receipts) + their buyers.
- 1 slightly larger shop with a **cashier** (tests staff roles + analytics).
Pick sellers who already complain about receipt books/paper costs — they
will forgive pilot roughness; do not start with your hardest skeptic.

## Setup day (per seller, ~30 minutes, do it WITH them)
1. Install the pilot build; create their account + PIN together.
2. Seller completes: receipt design → business verification form + documents
   → Seller Key backup code written down and stored safely.
3. You (admin): approve their verification in the admin panel the same day.
4. Buyer installs CA; buyer scans the seller's **Seller Key QR** (pairing).
5. **The exit test, together**: airplane mode ON on both phones → seller
   issues a real small sale → buyer scans → "Verified ✓" must appear in
   under a minute. If it fails, note exactly what happened and tell Muse.
6. If they have a thermal printer: pair it and print one QR slip.
7. Tap **Sync Now** once (with internet) so backups + registry flow.

Backend prep (once, Dennis): run `schema.sql`, `schema_v2_phase3.sql`,
`schema_v3_phase6.sql`; enable Anonymous sign-ins; create the admin user +
`admins` row; build with `dart_defines.json` (see CONNECT_SUPABASE.md).

## Week 1 — what to observe (write it down per pair)
- Time from "customer paid" to "buyer has Verified receipt" (target < 60s).
- Integrated sellers: how many captured receipts needed **manual correction**
  after OCR, and what was wrong (item names? quantities? totals?) — the
  Review screen shows corrections implicitly; ask them to count for 5 receipts.
- MoMo sales: does pending → confirm match how they actually work?
- Any moment they reached for the paper receipt book instead — why?
- Buyers: did they understand "Verified ✓" vs "not business-verified"?

## Feedback channels
- **In-app**: Home → Help & Feedback (goes to the pilot feedback table;
  share-sheet fallback when no server). Ask every participant to send at
  least one message in week 1 — even "it worked".
- **WhatsApp check-in** on day 3 and day 7 with the 5 pilot questions:
  1. Did CA slow you down at any sale? When?
  2. Did any receipt fail to scan or verify?
  3. What did you correct after capturing a receipt?
  4. Would you pay for this? How much per month feels fair?
  5. What one thing should we fix first?

## Issue log (keep in one place)
| Date | Pair | What happened | Screen/step | Severity (blocker/annoying/minor) | Status |
|---|---|---|---|---|---|
| | | | | | |

## Success criteria to move to Phase 7 (scale)
- ≥ 4 of 5 pairs complete the airplane-mode sale unaided by day 7.
- OCR: ≥ 80% of captured receipts need no total corrections.
- Zero lost receipts (everything issued appears in History + backups).
- At least 2 sellers say they would pay, unprompted, at a named price.

## Known pilot limitations (say them upfront — honesty builds trust)
- CA is **not GRA-certified**; receipts are CA-verified, tax reports are
  preparation only.
- Android-first; Bluetooth printing needs an ESC/POS thermal printer.
- History doesn't move to a new phone yet (signing key does — that's why
  step 2 of setup day matters).
- Twi covers the main screens; some forms are English (ask Twi-speaking
  sellers to mark the Help & Feedback "Confusing" items).
