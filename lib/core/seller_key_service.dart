import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'receipt_signer.dart';

/// The seller's Ed25519 signing key lives ONLY on this device, in secure
/// storage. The public key is what buyers use to verify receipts offline.
class SellerKeyService {
  static const _storage = FlutterSecureStorage();
  static String _seedKey(String businessId) => 'seller_seed_$businessId';

  static Future<ReceiptSigner> signerFor(String businessId) async {
    final stored = await _storage.read(key: _seedKey(businessId));
    if (stored != null) {
      return ReceiptSigner.fromSeed(base64Url.decode(_pad(stored)));
    }
    final kp = await Ed25519().newKeyPair();
    final priv = await kp.extractPrivateKeyBytes();
    await _storage.write(
        key: _seedKey(businessId),
        value: base64Url.encode(priv).replaceAll('=', ''));
    return ReceiptSigner.fromSeed(priv);
  }

  static String _pad(String s) => s + '=' * ((4 - s.length % 4) % 4);

  /// Pairing QR a buyer scans ONCE to learn this seller's public key
  /// (trust-on-first-use until the Supabase registry lands in Phase 3).
  /// Format: CAKEY1.(businessId).(publicKeyB64url).(urlEncoded business name)
  static String pairingQr(String businessId, String publicKeyB64, String businessName) =>
      'CAKEY1.$businessId.$publicKeyB64.${Uri.encodeComponent(businessName)}';

  static ({String businessId, String publicKeyB64, String businessName})? parsePairingQr(
      String text) {
    final parts = text.trim().split('.');
    if (parts.length != 4 || parts[0] != 'CAKEY1') return null;
    return (
      businessId: parts[1],
      publicKeyB64: parts[2],
      businessName: Uri.decodeComponent(parts[3]),
    );
  }

  static String newReceiptId() {
    final r = Random.secure();
    final suffix = List.generate(8, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    return 'r${DateTime.now().millisecondsSinceEpoch}-$suffix';
  }

  /// Current signing seed for this business (for CAKEYBACKUP1 export), or null.
  static Future<List<int>?> seedFor(String businessId) async {
    final signer = await signerFor(businessId);
    final kp = await signer.keyPairForBackup();
    return kp;
  }

  /// Restore a signing key from a CAKEYBACKUP1 seed (change-phone recovery).
  static Future<void> importSeed(String businessId, List<int> seed) async {
    await _storage.write(
        key: _seedKey(businessId),
        value: base64Url.encode(seed).replaceAll('=', ''));
  }
}
