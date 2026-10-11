import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'models.dart';

/// QR Payload Spec v1:
///   payload = base64url(canonicalJson) ; signed = payload + '.' + base64url(ed25519Sig)
/// Verification needs only the seller public key — fully offline.
/// See docs/QR_PAYLOAD_SPEC_V1.md
class ReceiptSigner {
  ReceiptSigner(this._keyPair);
  final KeyPair _keyPair;
  static final _algo = Ed25519();

  static Future<ReceiptSigner> generate() async =>
      ReceiptSigner(await _algo.newKeyPair());

  static Future<ReceiptSigner> fromSeed(List<int> seed) async =>
      ReceiptSigner(await _algo.newKeyPairFromSeed(seed));

  Future<String> publicKeyBase64Url() async {
    final kp = await _keyPair.extractPublicKey() as SimplePublicKey;
    return base64Url.encode(kp.bytes).replaceAll('=', '');
  }

  Future<String> signReceipt(Receipt receipt) async {
    final canonical = jsonEncode(receipt.toPayload());
    final payloadB64 = base64Url.encode(utf8.encode(canonical)).replaceAll('=', '');
    final sig = await _algo.sign(utf8.encode(payloadB64), keyPair: _keyPair);
    final sigB64 = base64Url.encode(sig.bytes).replaceAll('=', '');
    return 'CA1.$payloadB64.$sigB64';
  }

  static List<int> _b64d(String s) =>
      base64Url.decode(s + '=' * ((4 - s.length % 4) % 4));

  /// Returns the decoded receipt payload if the signature is valid, else null.
  static Future<Map<String, dynamic>?> verify(
      String qrText, List<int> sellerPublicKeyBytes) async {
    final parts = qrText.trim().split('.');
    if (parts.length != 3 || parts[0] != 'CA1') return null;
    try {
      final ok = await _algo.verify(
        utf8.encode(parts[1]),
        signature: Signature(_b64d(parts[2]),
            publicKey: SimplePublicKey(sellerPublicKeyBytes, type: KeyPairType.ed25519)),
      );
      if (!ok) return null;
      return jsonDecode(utf8.decode(_b64d(parts[1]))) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
