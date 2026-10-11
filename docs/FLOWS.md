# CA — User Flows v1 (Phase 0, plain-language diagrams for user testing)

## Buyer
```
Open CA (offline OK) → [Scan for Receipt] → point camera at seller QR
→ "✅ Verified — CA Demo Farms, Receipt CA-2026-0001, GH₵ 220.00" (or ⚠️ warning)
→ auto-saved → History: search / filter by seller & date → tap → detail
→ Share PDF · add category/note (Office, Farm inputs) · use for warranty/returns/expenses
Duplicates: "You already saved this receipt" → opens the saved copy.
```

## Seller — Integrated (has a receipt system already)
```
Your POS prints/displays receipt as usual
→ CA: [Capture Receipt] → photo / screen photo / upload image-PDF
→ OCR extracts items, totals, date, receipt no. (on-device, offline)
→ Review screen: photo on left, extracted fields on right, unsure fields highlighted
→ Correct if needed → [Approve] → CA issues signed QR (your original no. kept as reference)
→ Buyer scans the QR on your phone / printed slip / WhatsApp share
→ History: grouped by Buyer/Company → date & time
```

## Seller — Manual (handwritten receipts today)
```
Signup: register business → Design Receipt wizard (name/contact → logo →
template → VAT on/off → payment methods → footer) → submit for verification
→ Once Verified: [New Receipt] → buyer name (or recent buyers) →
add items (favourites are one tap) → app totals it (subtotal, discount, tax, TOTAL)
→ payment method → [Issue] → big QR → buyer scans on the spot
→ no smartphone? WhatsApp/SMS share, or Bluetooth-printed QR slip (Phase 4)
→ History: grouped by Buyer/Company → date & time
Target: a complete receipt in under 30 seconds.
```

## Business verification (all sellers)
```
Register business (legal/trading name, type, ORC no., TIN, VAT status,
address+GPS, category, owner Ghana Card for sole props)
→ status: Unverified (design + drafts only)
→ submit documents → Pending → admin reviews in Supabase-backed panel
→ Verified: signing key generated on device, public key published → can issue
→ Rejected: reason shown, fix and resubmit
```
