import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../seller_key_service.dart';
import '../services.dart';
import '../supabase_config.dart';
import 'key_wrap.dart';

/// Cloud account (Phase 8): turns the device's anonymous Supabase link
/// into a real email + password account *in place* (same uid — nothing
/// already backed up is orphaned), so an owner can sign in on another
/// phone and restore everything (see RestoreService). The local PIN
/// stays the on-device lock; this account is only for backup/restore
/// identity. Selling and scanning never need it.
class CloudAccountState {
  const CloudAccountState({
    required this.configured,
    required this.email,
    required this.anonymous,
    required this.signedOut,
  });
  final bool configured;
  final String? email;
  final bool anonymous;
  final bool signedOut;
}

class AccountService {
  static const _storage = FlutterSecureStorage();
  static const signedOutKey = 'cloud_signed_out';
  static const _emailKey = 'cloud_email';
  static const keyBlobKey = 'key_backup_blob';

  static SupabaseClient? get _client => SupabaseConfig.clientOrNull;

  static Future<CloudAccountState> state() async {
    final client = _client;
    final signedOut = await _storage.read(key: signedOutKey) == '1';
    final user = client?.auth.currentUser;
    return CloudAccountState(
      configured: client != null,
      email: user?.email ?? await _storage.read(key: _emailKey),
      anonymous: user?.isAnonymous ?? true,
      signedOut: signedOut,
    );
  }

  /// Attach email + password to this device's (anonymous) identity.
  /// Returns an error message, or null on success.
  static Future<String?> createAccount(String email, String password) async {
    final client = _client;
    if (client == null) return 'Supabase is not configured on this build.';
    try {
      var user = client.auth.currentUser;
      if (user == null) {
        await client.auth.signInAnonymously();
        user = client.auth.currentUser;
      }
      if (user != null && !user.isAnonymous) {
        return 'This device is already linked to ${user.email}.';
      }
      final res = await client.auth
          .updateUser(UserAttributes(email: email, password: password));
      await _storage.delete(key: signedOutKey);
      await _storage.write(key: _emailKey, value: email);
      await _stashKeyWrap(password);
      if (res.user?.email == null) {
        return 'Account created — tap the confirmation link in your email '
            'to finish, then Sync. (Tip for pilots: turn OFF "Confirm email" '
            'in Supabase to skip this step.)';
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Could not create the account (are you online?). $e';
    }
  }

  /// Sign in with an existing cloud account. Returns error or null.
  static Future<String?> signIn(String email, String password) async {
    final client = _client;
    if (client == null) return 'Supabase is not configured on this build.';
    try {
      await client.auth.signInWithPassword(email: email, password: password);
      await _storage.delete(key: signedOutKey);
      await _storage.write(key: _emailKey, value: email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Could not sign in (are you online?). $e';
    }
  }

  static Future<void> signOut() async {
    try {
      await _client?.auth.signOut();
    } catch (_) {}
    await _storage.write(key: signedOutKey, value: '1');
    await _storage.delete(key: _emailKey);
  }

  /// (Re)wrap the seller key with [password] and upload it now. Used at
  /// account creation and whenever the seller imports a new key.
  static Future<String?> refreshKeyBackup(String password) async {
    final client = _client;
    if (client == null) return 'Supabase is not configured on this build.';
    final ok = await _stashKeyWrap(password);
    if (!ok) return 'No seller key found on this phone to back up.';
    final user = client.auth.currentUser;
    if (user == null) return 'Sign in first, then back up the key.';
    try {
      await _pushKeyBlobNow(client, user.id);
      return null;
    } catch (e) {
      return 'Key wrapped on this phone; the upload will ride the next Sync. ($e)';
    }
  }

  /// Wraps this device's seller seed (if any) and mirrors the ciphertext
  /// in secure storage; SyncService uploads the mirror. Returns whether
  /// a seed existed.
  static Future<bool> _stashKeyWrap(String password) async {
    final profile = await AppServices.db.getProfile();
    final businessId = profile?.businessId;
    if (businessId == null) return false;
    final seed = await SellerKeyService.seedFor(businessId);
    if (seed == null) return false;
    final wrapped = await wrapSeed(seed, password);
    await _storage.write(key: keyBlobKey, value: jsonEncode(wrapped.toJson()));
    return true;
  }

  static Future<void> _pushKeyBlobNow(SupabaseClient client, String uid) async {
    final raw = await _storage.read(key: keyBlobKey);
    if (raw == null) return;
    final blob = WrappedKey.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final profile = await AppServices.db.getProfile();
    await client.from('profiles').upsert({
      'id': uid,
      'display_name': profile?.name ?? 'CA User',
      'phone': profile?.phone,
    });
    await client.from('account_backups').upsert({
      'owner_id': uid,
      'ca_business_id': profile?.businessId,
      'key_salt': blob.salt,
      'key_nonce': blob.nonce,
      'key_ciphertext': blob.ciphertext,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
