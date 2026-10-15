# CA v0.6.1 — ordered device retest script

Prepared 2026-10-14 evening, for the fix pack Dennis reported the same day
(8 items; #9 was the verification explainer). Run in THIS order — the order
is the point: the scan/share tests need an issued receipt first, and the
delete-account test destroys the local account, so it goes last and on a
throwaway account.

Prerequisite: install the v0.6.1 APK from the latest GitHub Actions run
(Actions tab → latest run → Artifacts → ca-app-release-apk). Confirm the
build is 0.6.1 before starting; results from 0.6.0 prove nothing about
this pack.

## Step 1 — Issue a receipt (setup for Steps 2–3)
- [ ] As a manual seller, issue one small receipt (2–3 items, one tax line).
- Note the receipt number and total — you will compare them in Step 2.

## Step 2 — Buyer scan display (his item 1)
- [ ] As buyer (second phone if available, else second account), scan the QR.
- Pass: full-screen result, status header matches reality (Verified /
  signed-not-verified / tampered), and EVERY line is readable: seller,
  receipt number, date, each item with qty × price, tax lines, total.
- Fail: report which line clips, truncates or garbles + a screenshot.

## Step 3 — WhatsApp share (his item 2)
- [ ] From the issued-receipt screen, share to WhatsApp.
- Pass: image arrives on a WHITE card (not black), and the QR in the
  WhatsApp image scans successfully from another phone/screen.
- Fail: send the received image back as-is.

## Step 4 — Back button (his item 3)
- [ ] Dashboard → open any sub-screen (e.g. History, Design) → Android back.
  Pass: returns to the dashboard, app does NOT exit.
- [ ] From a dashboard, press back again.
  Pass: returns to Home, app does NOT exit.

## Step 5 — OCR capture (his item 4; doubles as Phase 2 field test)
Use real receipts, not the demo: ideally 1 clean paper, 1 faded thermal,
1 photo of a PC screen.
- [ ] For each: capture → Review & Approve. Count how many ITEM lines and
  whether the TOTAL needed editing.
- Pass (pilot gate): total correct with no edit on ≥80% of receipts tried.
- Fail: keep the raw-text view screenshot for any receipt whose total
  was wrong — that is what tunes the parser.

## Step 6 — Scanner look (his item 5)
- [ ] Open the buyer scanner. Pass: squared rounded viewfinder, gold
  corners, sweeping scan line, dimmed surround. Cosmetic only — note
  anything misaligned, don't block on it.

## Step 7 — Business logo (his item 8)
- [ ] Design Receipt → upload a logo → issue a receipt.
- Pass: logo appears at the top of the issued-receipt screen, above the
  QR, with the footer note visible. Remove logo → confirm it disappears.

## Step 8 — Delete account (his item 6) — LAST, THROWAWAY ACCOUNT ONLY
Do NOT run this on your main/pilot seller account: deletion wipes the
phone (database + secure storage, including the local signing key if not
backed up) and removes server rows best-effort; verification documents
already submitted are retained by the admin by design.
- [ ] Create a throwaway account, then Settings (gear on Home) →
  Delete my account completely.
- [ ] Walk the steps: consequences list → acknowledgement ticks →
  PIN re-entry → final confirm.
- Pass: app returns to sign-up; signing back up fresh works; the
  throwaway account's data is gone from History.
- Also test one abort path: start deletion, back out at the PIN step —
  nothing should be deleted.

## Report back
One line per step: PASS, or FAIL + the screenshot/image noted above.
Steps 2, 3 and 5 are the ones that decide whether the fix pack is proven;
Steps 6–7 are cosmetic/secondary.
