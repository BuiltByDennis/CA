import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

/// Seller-key cloud backup (Phase 8). The Ed25519 seed IS the seller's
/// identity — password-grade secret — so it may only ever reach the
/// server wrapped: PBKDF2-HMAC-SHA256 (100k iterations) derives an
/// AES-256-GCM key from the owner's account password; the server stores
/// salt + nonce + ciphertext and can never read the seed. Losing the
/// password means losing this backup (the CAKEYBACKUP1 file still works).
class WrappedKey {
  const WrappedKey(this.salt, this.nonce, this.ciphertext);
  final String salt; // base64
  final String nonce; // base64
  final String ciphertext; // base64 (ciphertext + GCM tag)
  Map<String, String> toJson() => {'salt': salt, 'nonce': nonce, 'data': ciphertext};
  static WrappedKey fromJson(Map<String, dynamic> j) =>
      WrappedKey(j['salt'] as String, j['nonce'] as String, j['data'] as String);
}

const _iterations = 100000;

Future<SecretKey> _derive(String password, List<int> salt) => Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: 256,
    ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);

Future<WrappedKey> wrapSeed(List<int> seed, String password) async {
  final rand = Random.secure();
  final salt = List<int>.generate(16, (_) => rand.nextInt(256));
  final key = await _derive(password, salt);
  final algo = AesGcm.with256bits();
  final nonce = algo.newNonce();
  final box = await algo.encrypt(seed, secretKey: key, nonce: nonce);
  return WrappedKey(
    base64.encode(salt),
    base64.encode(nonce),
    base64.encode(box.concatenation()),
  );
}

/// Returns the seed, or null when the password is wrong / data is bad.
Future<List<int>?> unwrapSeed(WrappedKey wrapped, String password) async {
  try {
    final salt = base64.decode(wrapped.salt);
    final key = await _derive(password, salt);
    final algo = AesGcm.with256bits();
    final box = SecretBox.fromConcatenation(
      base64.decode(wrapped.ciphertext),
      nonceLength: algo.nonceLength,
      macLength: algo.macAlgorithm.macLength,
    );
    return await algo.decrypt(box, secretKey: key);
  } catch (_) {
    return null;
  }
}
