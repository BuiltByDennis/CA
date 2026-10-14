# Phase 2 — Notes (2026-10-14)

## Shipped
- **Capture screen** (integrated sellers): Take a Photo (camera) or Pick from Gallery/Screenshot (image_picker), plus an in-app guide for photographing a PC screen — the recommended path is screenshot-on-PC → send to phone → gallery, because moiré/glare are the top cause of OCR errors.
- **OCR service**: google_mlkit_text_recognition, on-device, offline. Images never leave the phone.
- **Receipt parser** (`lib/core/ocr/receipt_parser.dart`, pure Dart): seller header, receipt/invoice/bill/order number, date+time (d/m/y, ISO, and "09 Oct 2026" formats; ISO is parsed before d/m/y after a test caught 2026-10-09 misreading as 26/10/2009), items (qty × unit patterns: `2 x 45.00 90.00`, column qty `15 210.00 3,150.00`, single-price lines; thousands separators), tax lines (VAT/NHIL/GETFund/levy/tax summed), discount, subtotal, printed total, payment method detection.
- **Parser test set** (`test/receipt_parser_test.dart`): 10 representative receipts (supermarket, pharmacy, fuel, hardware, restaurant, small shop, electronics+discount, wholesaler, clinic, garbled screen-photo). Result: totals and receipt numbers correct on all 9 clean samples; the garbled sample is correctly *flagged* (totals mismatch warning + highlighted line) instead of trusted. 11/11 parser tests pass; 16/16 tests overall.
- **Review & Approve screen**: captured photo + raw OCR text expandable for comparison, parser warnings card, editable items/qty/unit price/tax/discount/payment/buyer/original receipt no., per-line "check this" highlighting, printed-total vs CA-total comparison (red when they differ). Approve → new CA sequential number, signed QR (reuses the Phase 1 issued-QR screen), saved to History (direction=issued, source=captured).
- **Drift schema v2**: `receipts.original_receipt_no` (the POS system's own number, kept for reference) with a proper onUpgrade migration.

## Honest limits
- **No device test yet.** ML Kit accuracy on real Ghana receipts (especially photographed PC screens) can only be measured on a real phone with real receipts — the parser tests prove the *parsing* logic on representative OCR text, not the OCR itself. Dennis's Phase 2 field test: capture 5 real receipts (mix of paper + screen) and note what needed correcting.
- **"Needs check" is validation, not OCR confidence.** ML Kit's Flutter API exposes no per-word confidence, so flags come from arithmetic validation (qty × unit ≠ amount, totals mismatch, garbled characters). Fields that are wrong but arithmetically consistent will not be flagged — that's why human approval is mandatory.
- **Discount representation**: a captured discount is stored as a negative `tx` line named "Discount" in the QR payload so buyer-side sum checks (items + tx == total) hold. A dedicated discount field is a QR Spec v2 candidate.
- **Tax from capture is a single lump** ("Tax (from receipt)") — the original receipt's VAT/NHIL/GETFund split is summed in review; per-line tax detail from capture is a later refinement.
- PDF receipt import not included (image/screenshot covers the PC case); virtual printer / POS API integrations remain Phase 5.
