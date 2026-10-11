# CA QR Payload Specification — v1 (FROZEN for Phase 1, versioned thereafter)

Status: Phase 0 deliverable, approved plan 2026-10-11. Changes require a new version (`CA2.` prefix) — v1 readers must keep working.

## Format
```
CA1.<base64url(canonical-json)>.<base64url(ed25519-signature)>
```
- Signature is over the ASCII bytes of the middle segment (the base64url payload string), **not** the raw JSON — this removes any canonicalisation ambiguity between sign and verify.
- No `=` padding. QR mode: Byte, error correction **M**.

## Canonical JSON payload (field order is canonical, keys are short to fit QR)
| Key | Meaning | Type |
|---|---|---|
| `v` | Spec version, always `1` | int |
| `id` | Receipt UUID (device-generated) | string |
| `no` | Seller-sequential receipt number e.g. `CA-2026-0001` | string |
| `sid` | Seller business ID | string |
| `sn` | Seller trading name | string |
| `bn` | Buyer name (optional — omitted for walk-in) | string |
| `it` | Items: `[{n:name, q:qty, p:unitPricePesewas}]` | array |
| `tx` | Tax lines: `[{n:name, r:ratePercent, a:amountPesewas}]` | array |
| `tot` | Total in pesewas (integer — never float) | int |
| `cur` | Currency, default `GHS` | string |
| `pm` | Payment method: Cash / MoMo / Bank / Card | string |
| `ts` | Issued-at, Unix seconds UTC | int |
| `src` | Source: `manual` \| `captured` \| `integrated` | string |

## Size limit & long receipts
Target payload ≤ 1,200 bytes (~fits a reliably scannable QR at M correction).
**Overflow rule (receipts with many items):** the QR carries a `summary form`:
same fields but `it` is replaced by `itc` (item count) + `ith` (SHA-256 hash of the full item list),
and the full receipt travels by (a) seller→buyer share (WhatsApp/Bluetooth) or (b) Supabase backup fetch when online.
The buyer app marks summary-form receipts "Details pending — full item list not yet received" until the full payload arrives and its hash matches `ith`. The total, seller, and signature in the summary form are still fully verified offline.

## Verification (buyer, offline)
1. Split on `.` — must be 3 parts, prefix `CA1`.
2. Look up seller public key by `sid` in the local key registry (cached from Supabase `seller_public_keys`; unknown seller → save as *Unverified — will confirm when online*, never as Verified).
3. Verify Ed25519 signature. Fail → hard warning, do not save as a receipt.
4. Check `id` against local DB — duplicate scan shows the existing saved receipt.
5. Check `tot` equals sum(items) + sum(tax) − discount when full items are present. Mismatch → tampered warning (signature should already prevent this; defence in depth).

## Keys
- Each verified business gets one Ed25519 device keypair, generated on the seller's device at verification approval. Private key lives ONLY in device secure storage (never sent to Supabase).
- Public key is published to `seller_public_keys` (Supabase) and cached by buyer devices.
- Lost phone: Phase 3 encrypted key-backup/recovery + key rotation — old key stays in the registry marked `superseded` so old receipts remain verifiable.
- Unverified businesses have no signing key and cannot issue `CA1.` QRs. Test/demo keys inside the app are labelled Demo and buyers reject them as Verified.
