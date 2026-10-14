import 'dart:convert';
import '../receipt_signer.dart';

/// Pure builders/filters for Supabase sync (Phase 3) — unit-tested.
/// The network layer (sync_service.dart) stays thin around these.

/// Build a receipts_backup row from a local outbox payload (the QR text).
/// Returns null when the QR cannot be decoded — such rows should be dropped,
/// not retried forever.
Map<String, Object?>? buildReceiptBackupRow(
  String qrText, {
  required String backedUpBy,
  String? sellerBusinessUuid,
}) {
  final payload = ReceiptSigner.decodePayloadUnverified(qrText);
  if (payload == null) return null;
  final ts = payload['ts'] as int? ?? 0;
  return {
    'id': payload['id'],
    'seller_business_id': sellerBusinessUuid,
    'payload': payload,
    'qr_text': qrText,
    'total_pesewas': payload['tot'] ?? 0,
    'issued_at': DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true)
        .toIso8601String(),
    'backed_up_by': backedUpBy,
  };
}

/// businesses row for submission (status is set to 'pending' by the caller
/// once docs are uploaded; keep this builder status-free).
Map<String, Object?> buildBusinessRow({
  required String ownerProfileId,
  String? existingId,
  String? caBusinessId,
  required String legalName,
  required String tradingName,
  required String businessType,
  required String sellerMode,
  String? orcNumber,
  String? tin,
  required bool vatRegistered,
  String? address,
  String? category,
  String? contactPhone,
  String? contactEmail,
}) {
  return {
    'id': ?existingId,
    'ca_business_id': caBusinessId,
    'owner_id': ownerProfileId,
    'legal_name': legalName,
    'trading_name': tradingName,
    'business_type': businessType,
    'seller_mode': sellerMode,
    'orc_number': orcNumber,
    'tin': tin,
    'vat_registered': vatRegistered,
    'address': address,
    'category': category,
    'contact_phone': contactPhone,
    'contact_email': contactEmail,
    'verification_status': 'pending',
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };
}

/// Registry filtering: from the full business + key lists, keep ONLY keys
/// whose business is verified AND whose key is active. Pairing (TOFU) keys
/// must never be upgraded by anything short of this.
List<({String businessId, String businessName, String publicKeyB64})>
    filterVerifiedKeys(
  List<Map<String, dynamic>> businesses,
  List<Map<String, dynamic>> keys,
) {
  // Supabase businesses are keyed by UUID, but receipt QR payloads carry the
  // seller's CA business ID (`biz-<phone>`) — the registry cache must be keyed
  // by the CA ID, via businesses.ca_business_id (schema v2).
  final verified = <String, ({String caId, String name})>{
    for (final b in businesses)
      if (b['verification_status'] == 'verified' && b['ca_business_id'] != null)
        b['id'] as String: (
          caId: b['ca_business_id'] as String,
          name: (b['trading_name'] as String? ?? 'Verified business'),
        ),
  };
  return [
    for (final k in keys)
      if (k['status'] == 'active' && verified.containsKey(k['business_id']))
        (
          businessId: verified[k['business_id']]!.caId,
          businessName: verified[k['business_id']]!.name,
          publicKeyB64: k['public_key_b64url'] as String,
        ),
  ];
}

/// Seller signing-key backup (change-phone recovery).
/// Format: CAKEYBACKUP1.(base64url seed)
/// The seed IS the private key — anyone holding it can issue as the seller.
/// The app must present it as a secret (like a password), never sync it.
String exportKeyBackup(List<int> seedBytes) =>
    'CAKEYBACKUP1.${base64Url.encode(seedBytes).replaceAll('=', '')}';

List<int>? parseKeyBackup(String text) {
  final parts = text.trim().split('.');
  if (parts.length != 2 || parts[0] != 'CAKEYBACKUP1') return null;
  try {
    final bytes = base64Url
        .decode(parts[1] + '=' * ((4 - parts[1].length % 4) % 4));
    return bytes.length == 32 ? bytes : null;
  } catch (_) {
    return null;
  }
}
