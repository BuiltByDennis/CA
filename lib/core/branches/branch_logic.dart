import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Active-branch selection (Phase 7). The branch list lives in Drift
/// (Branches table); which one is "current" on this device is a small
/// secure-storage value, and its name is stamped onto issued receipts.
class BranchService {
  static const _key = 'active_branch_name';
  static const _storage = FlutterSecureStorage();

  static Future<String?> activeBranchName() => _storage.read(key: _key);

  static Future<void> setActiveBranch(String? name) async {
    if (name == null) {
      await _storage.delete(key: _key);
    } else {
      await _storage.write(key: _key, value: name);
    }
  }
}
