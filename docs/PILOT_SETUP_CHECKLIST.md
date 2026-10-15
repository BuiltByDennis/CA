# CA — Consolidated Pilot Setup Checklist

One list, in order. Items marked [x] are already done (confirmed
2026-10-15). Detail scripts: docs/RETEST_V061.md (device retest) and
docs/PILOT_KIT.md (recruiting + setup day + week-1 observations).

## Already done
- [x] Supabase project created; schema.sql + schema_v2 + schema_v3 run
- [x] App connects ("Supabase: configured"); Sync identity works
- [x] Admin Auth user created
- [x] APK build pipeline (GitHub Actions) green; app downloaded

## A. Server — finish (5 minutes, at a computer)
- [ ] Run `supabase/schema_v4_phase7.sql` in the SQL Editor (referrals,
      subscriptions, MoMo payments tables)
- [ ] Confirm **Anonymous sign-ins** are ON (Authentication → Providers)
- [ ] Confirm the admins row exists:
      `select * from admins;` — if empty, insert your Auth user's UUID:
      `insert into admins (user_id) values ('THE-UUID');`

## B. Admin panel — first login
- [ ] Serve `admin/index.html` over http (e.g. `python3 -m http.server`
      in that folder; file:// will not load it)
- [ ] Enter Project URL + publishable key (this browser only, never
      service_role), sign in with the admin email/password
- [ ] You should land on the **Pending** queue — leave it open; pilot
      approvals happen here on setup days

## C. Your phone — install + prove the build
- [ ] Install the **0.7.0** APK (Actions → latest run → ca-app-release-apk);
      Home must show version 0.7.0 — older builds prove nothing
- [ ] Tap **Sync Now** — it must complete ("Sync complete: …")
- [ ] Run the ordered retest in docs/RETEST_V061.md:
      1. Issue a small receipt (setup)
      2. Buyer scan — full-screen result, every line readable
      3. WhatsApp share — white card, QR in the image scans back
      4. Back button — sub-screen → dashboard → Home, never exits
      5. OCR — 3 real receipts (clean paper, faded thermal, PC screen);
         target: total right with no edit on ≥ 80%
      6. Scanner look — squared viewfinder, gold corners, scan line
      7. Logo — Design Receipt upload → shows above the QR at issue
      8. Delete account — LAST, on a THROWAWAY account only
- [ ] One Bluetooth print on a real thermal printer (Print QR Slip)

## D. Recruit + setup day (per seller+buyer pair, ~30 min, WITH them)
- [ ] Recruit 5 pairs: 2 manual sellers, 2 integrated (POS) sellers,
      1 larger shop with a cashier — each with 2–3 regular buyers
- [ ] Install CA on the seller's phone; create account + PIN together
- [ ] Seller: Design Receipt → Business Verification form + documents →
      **Seller Key backup code written down and stored safely**
- [ ] You: approve their verification in the admin panel the same day
- [ ] Buyer installs CA; scans the seller's **Seller Key QR** (pairing)
- [ ] **Exit test together**: airplane mode ON on both phones → real
      small sale → buyer scans → Verified ✓ in under 60 seconds
- [ ] Seller taps **Sync Now** once (internet on) — backups + registry
- [ ] If they have a thermal printer: pair it, print one QR slip

## E. Pilot week
- [ ] Day 3 + Day 7 WhatsApp check-in with the 5 pilot questions
      (PILOT_KIT.md): slowed you down? any failed scan/verify? what did
      you correct after OCR? would you pay, how much? one fix first?
- [ ] Note every issue in one log: date, pair, what happened, screen,
      severity (blocker / annoying / minor)
- [ ] Ask every participant to send one in-app Help & Feedback message

## Pilot gate — Phase 7 scale decisions rest on this
- ≥ 4 of 5 pairs do the airplane-mode sale unaided by day 7
- OCR: ≥ 80% of captures need no total corrections
- Zero lost receipts
- ≥ 2 sellers name a price they'd pay, unprompted

## Honest limits to state to sellers upfront
- CA is **not GRA-certified**; tax reports are preparation only
- Android only for the pilot (iOS build is unsigned/experimental)
- History doesn't move to a new phone yet — the signing-key backup does,
  which is why setup-day step "key backup" matters
- MoMo auto-confirmation is not live yet (needs the MTN merchant
  account); manual Confirm in History is the pilot flow
