import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Local PIN auth — offline by design (plan Phase 1).
/// PIN is stored ONLY as a salted SHA-256 hash in secure storage.
/// Supabase Auth (phone OTP) layers on top for backup/verification in Phase 3;
/// it must never become required to open the app offline.
class SessionService {
  static const _storage = FlutterSecureStorage();
  static const _saltKey = 'ca_pin_salt';
  static const _hashKey = 'ca_pin_hash';
  static bool unlocked = false;

  static Future<String> _hash(String pin, String salt) async {
    final h = await Sha256().hash(utf8.encode('$salt:$pin'));
    return base64Url.encode(h.bytes);
  }

  static Future<void> setPin(String pin) async {
    final salt = List.generate(16, (_) => Random.secure().nextInt(256)).join('-');
    await _storage.write(key: _saltKey, value: salt);
    await _storage.write(key: _hashKey, value: await _hash(pin, salt));
    unlocked = true;
  }

  static Future<bool> hasPin() async => await _storage.read(key: _hashKey) != null;

  static Future<bool> tryUnlock(String pin) async {
    final salt = await _storage.read(key: _saltKey);
    final expected = await _storage.read(key: _hashKey);
    if (salt == null || expected == null) return false;
    unlocked = await _hash(pin, salt) == expected;
    return unlocked;
  }

  static void lock() => unlocked = false;
}
